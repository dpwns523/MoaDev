terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0.0"
    }
  }
}

locals {
  create_mode      = var.network_mode == "create"
  planned_vpc_name = format("%s-aws-vpc", var.name_prefix)
  nat_gateway_mode = trimspace(var.nat_gateway_mode) == "" ? "single" : var.nat_gateway_mode

  control_plane_subnet_plan = local.create_mode ? [
    for index, cidr in var.control_plane_subnet_cidrs : {
      name              = format("%s-aws-control-plane-%02d", var.name_prefix, index + 1)
      cidr              = cidr
      availability_zone = var.availability_zones[index % length(var.availability_zones)]
      role              = "control-plane"
      visibility        = "private"
    }
  ] : []

  worker_subnet_plan = local.create_mode ? [
    for index, cidr in var.worker_subnet_cidrs : {
      name              = format("%s-aws-worker-%02d", var.name_prefix, index + 1)
      cidr              = cidr
      availability_zone = var.availability_zones[index % length(var.availability_zones)]
      role              = "worker"
      visibility        = "private"
    }
  ] : []

  public_load_balancer_subnet_plan = local.create_mode ? [
    for index, cidr in var.public_load_balancer_subnet_cidrs : {
      name              = format("%s-aws-public-lb-%02d", var.name_prefix, index + 1)
      cidr              = cidr
      availability_zone = var.availability_zones[index % length(var.availability_zones)]
      role              = "load-balancer"
      visibility        = "public"
    }
  ] : []

  control_plane_subnet_map = {
    for subnet in local.control_plane_subnet_plan :
    subnet.name => subnet
  }

  worker_subnet_map = {
    for subnet in local.worker_subnet_plan :
    subnet.name => subnet
  }

  public_load_balancer_subnet_map = {
    for subnet in local.public_load_balancer_subnet_plan :
    subnet.name => subnet
  }

  vpc_ref = local.create_mode ? try(aws_vpc.this[0].id, local.planned_vpc_name) : var.existing_vpc_id

  control_plane_subnet_refs = local.create_mode ? [
    for name in sort(keys(aws_subnet.control_plane)) :
    aws_subnet.control_plane[name].id
  ] : var.existing_control_plane_subnet_ids

  worker_subnet_refs = local.create_mode ? [
    for name in sort(keys(aws_subnet.worker)) :
    aws_subnet.worker[name].id
  ] : var.existing_worker_subnet_ids

  public_load_balancer_subnet_refs = local.create_mode ? [
    for name in sort(keys(aws_subnet.public_load_balancer)) :
    aws_subnet.public_load_balancer[name].id
  ] : var.existing_public_load_balancer_subnet_ids

  nat_gateway_enabled = local.create_mode && var.nat_gateway_enabled
  private_egress_mode = (
    local.create_mode
    ? (
      local.nat_gateway_enabled
      ? format("nat-gateway-%s", local.nat_gateway_mode)
      : "none"
    )
    : "reference"
  )

  kubespray_security_profile_enabled = var.security_profile == "kubespray-default"

  control_plane_internal_ingress_rules = {
    for index, cidr in var.cluster_internal_cidrs :
    format("internal-%02d", index + 1) => cidr
  }

  worker_internal_ingress_rules = {
    for index, cidr in var.cluster_internal_cidrs :
    format("internal-%02d", index + 1) => cidr
  }

  control_plane_admin_ingress_rules = var.ssh_access_mode == "cidr_allowlist" ? {
    for index, cidr in var.admin_ingress_cidrs :
    format("ssh-admin-%02d", index + 1) => cidr
  } : {}

  worker_admin_ingress_rules = var.ssh_access_mode == "cidr_allowlist" ? {
    for index, cidr in var.admin_ingress_cidrs :
    format("ssh-admin-%02d", index + 1) => cidr
  } : {}

  control_plane_api_ingress_rules = var.kube_api_access_mode == "public_allowlist" ? {
    for index, cidr in var.kube_api_ingress_cidrs :
    format("kube-api-%02d", index + 1) => cidr
  } : {}
}

resource "aws_vpc" "this" {
  count = local.create_mode ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.labels, {
    Name = local.planned_vpc_name
  })
}

resource "aws_internet_gateway" "public" {
  count = local.create_mode ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = merge(var.labels, {
    Name = format("%s-aws-igw", var.name_prefix)
  })
}

resource "aws_eip" "nat" {
  count = local.nat_gateway_enabled ? 1 : 0

  domain = "vpc"

  tags = merge(var.labels, {
    Name = format("%s-aws-nat-eip", var.name_prefix)
  })
}

resource "aws_nat_gateway" "private" {
  count = local.nat_gateway_enabled ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = local.public_load_balancer_subnet_refs[0]

  tags = merge(var.labels, {
    Name = format("%s-aws-nat", var.name_prefix)
  })

  depends_on = [aws_internet_gateway.public]
}

resource "aws_subnet" "control_plane" {
  for_each = local.create_mode ? local.control_plane_subnet_map : {}

  vpc_id            = aws_vpc.this[0].id
  cidr_block        = each.value.cidr
  availability_zone = each.value.availability_zone

  tags = merge(var.labels, {
    Name       = each.value.name
    Role       = each.value.role
    Visibility = each.value.visibility
  })
}

resource "aws_subnet" "worker" {
  for_each = local.create_mode ? local.worker_subnet_map : {}

  vpc_id            = aws_vpc.this[0].id
  cidr_block        = each.value.cidr
  availability_zone = each.value.availability_zone

  tags = merge(var.labels, {
    Name       = each.value.name
    Role       = each.value.role
    Visibility = each.value.visibility
  })
}

resource "aws_subnet" "public_load_balancer" {
  for_each = local.create_mode ? local.public_load_balancer_subnet_map : {}

  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(var.labels, {
    Name       = each.value.name
    Role       = each.value.role
    Visibility = each.value.visibility
  })
}

resource "aws_route_table" "private" {
  count = local.create_mode ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = merge(var.labels, {
    Name = format("%s-aws-private-rt", var.name_prefix)
  })
}

resource "aws_route" "private_default_egress" {
  count = local.nat_gateway_enabled ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.private[0].id
}

resource "aws_route_table" "public" {
  count = local.create_mode ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public[0].id
  }

  tags = merge(var.labels, {
    Name = format("%s-aws-public-rt", var.name_prefix)
  })
}

resource "aws_route_table_association" "control_plane" {
  for_each = local.create_mode ? aws_subnet.control_plane : {}

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "worker" {
  for_each = local.create_mode ? aws_subnet.worker : {}

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "public_load_balancer" {
  for_each = local.create_mode ? aws_subnet.public_load_balancer : {}

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_security_group" "control_plane" {
  name        = format("%s-aws-control-plane", var.name_prefix)
  description = "Control-plane access boundary for MoaDev VM foundations."
  vpc_id      = local.vpc_ref

  tags = merge(var.labels, {
    Name = format("%s-aws-control-plane", var.name_prefix)
    Role = "control-plane"
  })
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_internal" {
  for_each = local.control_plane_internal_ingress_rules

  security_group_id = aws_security_group.control_plane.id
  description       = format("Allow cluster-internal traffic from %s", each.value)
  cidr_ipv4         = each.value
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_admin_ssh" {
  for_each = local.control_plane_admin_ingress_rules

  security_group_id = aws_security_group.control_plane.id
  description       = format("Allow operator SSH from %s", each.value)
  cidr_ipv4         = each.value
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_kube_api" {
  for_each = local.control_plane_api_ingress_rules

  security_group_id = aws_security_group.control_plane.id
  description       = format("Allow Kubernetes API from %s", each.value)
  cidr_ipv4         = each.value
  from_port         = 6443
  to_port           = 6443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "control_plane_all" {
  security_group_id = aws_security_group.control_plane.id
  description       = "Allow all outbound traffic from control-plane nodes."
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "worker" {
  name        = format("%s-aws-worker", var.name_prefix)
  description = "Worker access boundary for MoaDev VM foundations."
  vpc_id      = local.vpc_ref

  tags = merge(var.labels, {
    Name = format("%s-aws-worker", var.name_prefix)
    Role = "worker"
  })
}

resource "aws_vpc_security_group_ingress_rule" "worker_internal" {
  for_each = local.worker_internal_ingress_rules

  security_group_id = aws_security_group.worker.id
  description       = format("Allow cluster-internal traffic from %s", each.value)
  cidr_ipv4         = each.value
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "worker_admin_ssh" {
  for_each = local.worker_admin_ingress_rules

  security_group_id = aws_security_group.worker.id
  description       = format("Allow operator SSH from %s", each.value)
  cidr_ipv4         = each.value
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "worker_all" {
  security_group_id = aws_security_group.worker.id
  description       = "Allow all outbound traffic from worker nodes."
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

check "supported_network_mode" {
  assert {
    condition     = contains(["create", "reference"], var.network_mode)
    error_message = "network_mode must be either create or reference."
  }
}

check "supported_nat_gateway_mode" {
  assert {
    condition = (
      !local.nat_gateway_enabled ||
      contains(["single"], local.nat_gateway_mode)
    )
    error_message = "nat_gateway_mode must currently be set to single when AWS NAT egress is enabled."
  }
}

check "supported_security_profile" {
  assert {
    condition     = local.kubespray_security_profile_enabled
    error_message = "security_profile must currently be set to kubespray-default for AWS VM foundations."
  }
}

check "supported_ssh_access_mode" {
  assert {
    condition     = contains(["none", "cidr_allowlist"], var.ssh_access_mode)
    error_message = "ssh_access_mode must be either none or cidr_allowlist."
  }
}

check "supported_kube_api_access_mode" {
  assert {
    condition     = contains(["private_only", "public_allowlist"], var.kube_api_access_mode)
    error_message = "kube_api_access_mode must be either private_only or public_allowlist."
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

check "public_kube_api_requires_cidrs" {
  assert {
    condition = (
      var.kube_api_access_mode != "public_allowlist" ||
      length(var.kube_api_ingress_cidrs) > 0
    )
    error_message = "kube_api_ingress_cidrs must be provided when kube_api_access_mode is public_allowlist."
  }
}

check "cluster_internal_cidrs_are_required" {
  assert {
    condition     = length(var.cluster_internal_cidrs) > 0
    error_message = "cluster_internal_cidrs must include at least one cluster-internal CIDR."
  }
}

check "create_mode_has_required_network_inputs" {
  assert {
    condition = (
      !local.create_mode ||
      (
        can(cidrhost(var.vpc_cidr, 0)) &&
        length(var.availability_zones) > 0 &&
        length(var.control_plane_subnet_cidrs) > 0 &&
        length(var.worker_subnet_cidrs) > 0 &&
        length(var.public_load_balancer_subnet_cidrs) > 0 &&
        alltrue([
          for cidr in concat(
            var.control_plane_subnet_cidrs,
            var.worker_subnet_cidrs,
            var.public_load_balancer_subnet_cidrs
          ) :
          can(cidrhost(cidr, 0))
        ])
      )
    )
    error_message = "create mode requires vpc_cidr, availability_zones, and valid CIDRs for all subnet groups."
  }
}

check "reference_mode_has_existing_network_ids" {
  assert {
    condition = (
      local.create_mode ||
      (
        trimspace(var.existing_vpc_id) != "" &&
        length(var.existing_control_plane_subnet_ids) > 0 &&
        length(var.existing_worker_subnet_ids) > 0 &&
        length(var.existing_public_load_balancer_subnet_ids) > 0 &&
        alltrue([
          for subnet_id in concat(
            var.existing_control_plane_subnet_ids,
            var.existing_worker_subnet_ids,
            var.existing_public_load_balancer_subnet_ids
          ) :
          trimspace(subnet_id) != ""
        ])
      )
    )
    error_message = "reference mode requires existing VPC and subnet identifiers for all subnet groups."
  }
}
