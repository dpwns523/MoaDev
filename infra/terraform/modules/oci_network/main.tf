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

  worker_subnet_refs = local.create_mode ? [
    for name in sort(keys(oci_core_subnet.worker)) :
    oci_core_subnet.worker[name].id
  ] : var.existing_worker_subnet_ocids
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

check "reference_mode_has_existing_network_ids" {
  assert {
    condition = (
      local.create_mode ||
      (
        trimspace(var.existing_vcn_ocid) != "" &&
        length(var.existing_worker_subnet_ocids) > 0 &&
        alltrue([
          for subnet_id in var.existing_worker_subnet_ocids :
          trimspace(subnet_id) != ""
        ])
      )
    )
    error_message = "reference mode requires existing VCN and worker subnet identifiers."
  }
}
