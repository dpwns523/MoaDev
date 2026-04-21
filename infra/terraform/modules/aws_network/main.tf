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
