terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0, < 6.0.0"
    }
  }
}

locals {
  create_mode      = var.network_mode == "create"
  planned_vcn_name = format("%s-oci-vcn", var.name_prefix)
  nat_gateway_mode = local.create_mode && var.nat_gateway_enabled ? "nat-gateway-single" : (local.create_mode ? "none" : "reference")

  worker_subnet_plan = local.create_mode ? [
    for index, cidr in var.worker_subnet_cidrs : {
      name                = format("%s-oci-worker-%02d", var.name_prefix, index + 1)
      cidr                = cidr
      availability_domain = var.availability_domains[index % length(var.availability_domains)]
      role                = "worker"
      visibility          = "private"
    }
  ] : []

  worker_subnet_map = {
    for subnet in local.worker_subnet_plan :
    subnet.name => subnet
  }

  vcn_ref = local.create_mode ? try(oci_core_vcn.this[0].id, local.planned_vcn_name) : var.existing_vcn_ocid

  worker_subnet_bindings = local.create_mode ? [
    for name in sort(keys(oci_core_subnet.worker)) : {
      subnet_id           = oci_core_subnet.worker[name].id
      availability_domain = oci_core_subnet.worker[name].availability_domain
    }
  ] : var.existing_worker_subnet_bindings

  kubespray_security_profile_enabled = var.security_profile == "kubespray-default"

  worker_internal_ingress_rules = {
    for index, cidr in var.cluster_internal_cidrs :
    format("internal-%02d", index + 1) => cidr
  }

  worker_admin_ingress_rules = var.ssh_access_mode == "cidr_allowlist" ? {
    for index, cidr in var.admin_ingress_cidrs :
    format("ssh-admin-%02d", index + 1) => cidr
  } : {}
}

resource "oci_core_vcn" "this" {
  count = local.create_mode ? 1 : 0

  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = local.planned_vcn_name
  freeform_tags  = var.labels
}

resource "oci_core_nat_gateway" "worker" {
  count = local.create_mode && var.nat_gateway_enabled ? 1 : 0

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this[0].id
  display_name   = format("%s-oci-worker-nat", var.name_prefix)
  freeform_tags  = var.labels
}

resource "oci_core_route_table" "worker_private" {
  count = local.create_mode ? 1 : 0

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this[0].id
  display_name   = format("%s-oci-worker-private-rt", var.name_prefix)
  freeform_tags  = var.labels

  dynamic "route_rules" {
    for_each = local.create_mode && var.nat_gateway_enabled ? [1] : []

    content {
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_nat_gateway.worker[0].id
    }
  }
}

resource "oci_core_subnet" "worker" {
  for_each = local.create_mode ? local.worker_subnet_map : {}

  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this[0].id
  route_table_id             = oci_core_route_table.worker_private[0].id
  cidr_block                 = each.value.cidr
  display_name               = each.value.name
  availability_domain        = each.value.availability_domain
  prohibit_public_ip_on_vnic = true

  freeform_tags = merge(var.labels, {
    Role       = each.value.role
    Visibility = each.value.visibility
  })
}

resource "oci_core_network_security_group" "worker" {
  compartment_id = var.compartment_ocid
  vcn_id         = local.vcn_ref
  display_name   = format("%s-oci-worker", var.name_prefix)
  freeform_tags  = merge(var.labels, { Role = "worker" })
}

resource "oci_core_network_security_group_security_rule" "worker_internal" {
  for_each = local.worker_internal_ingress_rules

  network_security_group_id = oci_core_network_security_group.worker.id
  description               = format("Allow cluster-internal traffic from %s", each.value)
  direction                 = "INGRESS"
  protocol                  = "all"
  source                    = each.value
  source_type               = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "worker_admin_ssh" {
  for_each = local.worker_admin_ingress_rules

  network_security_group_id = oci_core_network_security_group.worker.id
  description               = format("Allow operator SSH from %s", each.value)
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "worker_all_egress" {
  network_security_group_id = oci_core_network_security_group.worker.id
  description               = "Allow all outbound traffic from worker nodes."
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

check "supported_network_mode" {
  assert {
    condition     = contains(["create", "reference"], var.network_mode)
    error_message = "network_mode must be either create or reference."
  }
}

check "create_mode_has_required_network_inputs" {
  assert {
    condition = (
      !local.create_mode ||
      (
        can(cidrhost(var.vcn_cidr, 0)) &&
        length(var.availability_domains) > 0 &&
        length(var.worker_subnet_cidrs) > 0 &&
        alltrue([
          for cidr in var.worker_subnet_cidrs :
          can(cidrhost(cidr, 0))
        ])
      )
    )
    error_message = "create mode requires vcn_cidr, availability_domains, and valid worker subnet CIDRs."
  }
}

check "supported_security_profile" {
  assert {
    condition     = local.kubespray_security_profile_enabled
    error_message = "security_profile must currently be set to kubespray-default for OCI VM foundations."
  }
}

check "supported_ssh_access_mode" {
  assert {
    condition     = contains(["none", "cidr_allowlist"], var.ssh_access_mode)
    error_message = "ssh_access_mode must be either none or cidr_allowlist."
  }
}

check "ssh_allowlist_requires_cidrs" {
  assert {
    condition = (
      var.ssh_access_mode != "cidr_allowlist" ||
      length(var.admin_ingress_cidrs) > 0
    )
    error_message = "admin_ingress_cidrs must be provided when ssh_access_mode is cidr_allowlist."
  }
}

check "cluster_internal_cidrs_are_required" {
  assert {
    condition     = length(var.cluster_internal_cidrs) > 0
    error_message = "cluster_internal_cidrs must include at least one cluster-internal CIDR."
  }
}

check "reference_mode_has_existing_network_ids" {
  assert {
    condition = (
      local.create_mode ||
      (
        trimspace(var.existing_vcn_ocid) != "" &&
        length(var.existing_worker_subnet_bindings) > 0 &&
        alltrue([
          for binding in var.existing_worker_subnet_bindings :
          trimspace(binding.subnet_id) != "" && trimspace(binding.availability_domain) != ""
        ])
      )
    )
    error_message = "reference mode requires existing VCN and worker subnet identifiers."
  }
}
