terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0.0"
    }
  }
}

locals {
  aws_node_groups = {
    for name, node_group in var.cluster_topology.node_groups :
    name => node_group if node_group.provider == "aws"
  }

  aws_control_plane_node_groups = {
    for name, node_group in local.aws_node_groups :
    name => node_group if node_group.role == "control-plane"
  }

  aws_worker_node_groups = {
    for name, node_group in local.aws_node_groups :
    name => node_group if node_group.role == "worker"
  }

  normalized_key_name             = trimspace(coalesce(var.ssh_key_name, "")) == "" ? null : trimspace(var.ssh_key_name)
  normalized_instance_profile     = trimspace(coalesce(var.instance_profile_name, "")) == "" ? null : trimspace(var.instance_profile_name)
  normalized_bootstrap_path       = trimspace(coalesce(var.bootstrap_template_path, ""))
  aws_instance_resources_enabled  = trimspace(coalesce(var.ami_id, "")) != ""
  control_plane_resources_enabled = local.aws_instance_resources_enabled && length(var.control_plane_subnet_refs) > 0
  worker_resources_enabled        = local.aws_instance_resources_enabled && length(var.worker_subnet_refs) > 0

  control_plane_plan = {
    for name, node_group in local.aws_control_plane_node_groups :
    name => {
      provider                  = "aws"
      role                      = node_group.role
      desired_count             = node_group.desired_count
      min_count                 = node_group.min_count
      max_count                 = node_group.max_count
      scaling_strategy          = node_group.scaling_strategy
      instance_type             = var.control_plane_instance_type
      root_volume_gbs           = var.control_plane_root_volume_gbs
      subnet_refs               = var.control_plane_subnet_refs
      endpoint_access_intent    = var.control_plane_endpoint_access_intent
      placement_intent          = var.control_plane_placement_intent
      storage_class             = var.storage_class
      supports_future_scale_out = node_group.max_count > node_group.desired_count
      labels                    = var.labels
      resource_name_prefix      = format("%s-%s", var.name_prefix, name)
    }
  }

  worker_plan = {
    for name, node_group in local.aws_worker_node_groups :
    name => {
      provider             = "aws"
      role                 = node_group.role
      desired_count        = node_group.desired_count
      min_count            = node_group.min_count
      max_count            = node_group.max_count
      scaling_strategy     = node_group.scaling_strategy
      instance_type        = var.worker_instance_type
      root_volume_gbs      = var.worker_root_volume_gbs
      subnet_refs          = var.worker_subnet_refs
      placement_intent     = var.worker_placement_intent
      storage_class        = var.storage_class
      spot_enabled         = var.worker_spot_enabled
      labels               = var.labels
      resource_name_prefix = format("%s-%s", var.name_prefix, name)
    }
  }

  node_group_plan = merge(local.control_plane_plan, local.worker_plan)

  control_plane_instance_plan = merge({}, [
    for name, node_group in local.control_plane_plan : {
      for index in range(node_group.desired_count) :
      format("%s-%02d", node_group.resource_name_prefix, index + 1) => merge(node_group, {
        node_group_name = name
        instance_name   = format("%s-%02d", node_group.resource_name_prefix, index + 1)
        ordinal         = index + 1
        subnet_id = (
          length(node_group.subnet_refs) == 0
          ? null
          : node_group.subnet_refs[index % length(node_group.subnet_refs)]
        )
        bootstrap_user_data = (
          local.normalized_bootstrap_path != "" && fileexists(local.normalized_bootstrap_path)
          ? templatefile(local.normalized_bootstrap_path, {
            cluster_name                         = var.cluster_topology.cluster_name
            kubernetes_version                   = var.cluster_topology.kubernetes_version
            node_group_name                      = name
            node_role                            = node_group.role
            instance_name                        = format("%s-%02d", node_group.resource_name_prefix, index + 1)
            storage_class                        = var.storage_class
            control_plane_endpoint_access_intent = var.control_plane_endpoint_access_intent
            placement_intent                     = var.control_plane_placement_intent
            cloud_provider                       = "aws"
          })
          : <<-EOT
            #!/bin/bash
            set -euxo pipefail
            install -d -m 0755 /etc/moadev
            cat >/etc/moadev/node-profile.env <<'EOF'
            MOADEV_CLUSTER_NAME=${var.cluster_topology.cluster_name}
            MOADEV_KUBERNETES_VERSION=${var.cluster_topology.kubernetes_version}
            MOADEV_NODE_GROUP=${name}
            MOADEV_NODE_ROLE=${node_group.role}
            MOADEV_INSTANCE_NAME=${format("%s-%02d", node_group.resource_name_prefix, index + 1)}
            MOADEV_STORAGE_CLASS=${var.storage_class}
            MOADEV_CONTROL_PLANE_ENDPOINT_ACCESS_INTENT=${var.control_plane_endpoint_access_intent}
            MOADEV_PLACEMENT_INTENT=${var.control_plane_placement_intent}
            EOF
            echo "TODO: replace placeholder bootstrap with Kubespray or host bootstrap workflow" >/etc/motd
          EOT
        )
      })
    }
  ]...)

  worker_instance_plan = merge({}, [
    for name, node_group in local.worker_plan : {
      for index in range(node_group.desired_count) :
      format("%s-%02d", node_group.resource_name_prefix, index + 1) => merge(node_group, {
        node_group_name = name
        instance_name   = format("%s-%02d", node_group.resource_name_prefix, index + 1)
        ordinal         = index + 1
        subnet_id = (
          length(node_group.subnet_refs) == 0
          ? null
          : node_group.subnet_refs[index % length(node_group.subnet_refs)]
        )
        bootstrap_user_data = (
          local.normalized_bootstrap_path != "" && fileexists(local.normalized_bootstrap_path)
          ? templatefile(local.normalized_bootstrap_path, {
            cluster_name                         = var.cluster_topology.cluster_name
            kubernetes_version                   = var.cluster_topology.kubernetes_version
            node_group_name                      = name
            node_role                            = node_group.role
            instance_name                        = format("%s-%02d", node_group.resource_name_prefix, index + 1)
            storage_class                        = var.storage_class
            control_plane_endpoint_access_intent = var.control_plane_endpoint_access_intent
            placement_intent                     = var.worker_placement_intent
            cloud_provider                       = "aws"
          })
          : <<-EOT
            #!/bin/bash
            set -euxo pipefail
            install -d -m 0755 /etc/moadev
            cat >/etc/moadev/node-profile.env <<'EOF'
            MOADEV_CLUSTER_NAME=${var.cluster_topology.cluster_name}
            MOADEV_KUBERNETES_VERSION=${var.cluster_topology.kubernetes_version}
            MOADEV_NODE_GROUP=${name}
            MOADEV_NODE_ROLE=${node_group.role}
            MOADEV_INSTANCE_NAME=${format("%s-%02d", node_group.resource_name_prefix, index + 1)}
            MOADEV_STORAGE_CLASS=${var.storage_class}
            MOADEV_WORKER_SPOT_ENABLED=${var.worker_spot_enabled}
            MOADEV_CONTROL_PLANE_ENDPOINT_ACCESS_INTENT=${var.control_plane_endpoint_access_intent}
            MOADEV_PLACEMENT_INTENT=${var.worker_placement_intent}
            EOF
            echo "TODO: replace placeholder bootstrap with Kubespray or host bootstrap workflow" >/etc/motd
          EOT
        )
      })
    }
  ]...)
}

resource "aws_instance" "control_plane" {
  for_each = local.control_plane_resources_enabled ? local.control_plane_instance_plan : {}

  ami                         = local.aws_instance_resources_enabled ? var.ami_id : "ami-disabled-placeholder"
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = var.control_plane_security_group_ids
  key_name                    = local.normalized_key_name
  iam_instance_profile        = local.normalized_instance_profile
  user_data                   = each.value.bootstrap_user_data
  associate_public_ip_address = false
  monitoring                  = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = each.value.root_volume_gbs
    volume_type           = "gp3"
  }

  tags = merge(each.value.labels, {
    Name                     = each.value.instance_name
    ClusterName              = var.cluster_topology.cluster_name
    KubernetesRole           = each.value.role
    NodeGroup                = each.value.node_group_name
    StorageClass             = each.value.storage_class
    ControlPlaneAccessIntent = each.value.endpoint_access_intent
    ManagedBy                = "terraform"
  })
}

resource "aws_instance" "worker" {
  for_each = local.worker_resources_enabled ? local.worker_instance_plan : {}

  ami                         = local.aws_instance_resources_enabled ? var.ami_id : "ami-disabled-placeholder"
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = var.worker_security_group_ids
  key_name                    = local.normalized_key_name
  iam_instance_profile        = local.normalized_instance_profile
  user_data                   = each.value.bootstrap_user_data
  associate_public_ip_address = false
  monitoring                  = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = each.value.root_volume_gbs
    volume_type           = "gp3"
  }

  dynamic "instance_market_options" {
    for_each = each.value.spot_enabled ? [1] : []

    content {
      market_type = "spot"

      spot_options {
        instance_interruption_behavior = "terminate"
        spot_instance_type             = "one-time"
      }
    }
  }

  tags = merge(each.value.labels, {
    Name           = each.value.instance_name
    ClusterName    = var.cluster_topology.cluster_name
    KubernetesRole = each.value.role
    NodeGroup      = each.value.node_group_name
    StorageClass   = each.value.storage_class
    SpotEnabled    = tostring(each.value.spot_enabled)
    ManagedBy      = "terraform"
  })
}

check "aws_control_plane_groups_have_subnets" {
  assert {
    condition     = length(local.aws_control_plane_node_groups) == 0 || length(var.control_plane_subnet_refs) > 0
    error_message = "AWS control-plane node groups require at least one control-plane subnet reference."
  }
}

check "aws_worker_groups_have_subnets" {
  assert {
    condition     = length(local.aws_worker_node_groups) == 0 || length(var.worker_subnet_refs) > 0
    error_message = "AWS worker node groups require at least one worker subnet reference."
  }
}

check "aws_control_plane_groups_have_security_groups" {
  assert {
    condition     = length(local.aws_control_plane_node_groups) == 0 || length(var.control_plane_security_group_ids) > 0
    error_message = "AWS control-plane node groups require explicit security groups."
  }
}

check "aws_worker_groups_have_security_groups" {
  assert {
    condition     = length(local.aws_worker_node_groups) == 0 || length(var.worker_security_group_ids) > 0
    error_message = "AWS worker node groups require explicit security groups."
  }
}

check "aws_volume_sizes_are_positive" {
  assert {
    condition     = var.control_plane_root_volume_gbs > 0 && var.worker_root_volume_gbs > 0
    error_message = "AWS root volume sizes must be positive."
  }
}

check "aws_compute_groups_require_ami" {
  assert {
    condition = (
      length(local.aws_node_groups) == 0 ||
      trimspace(coalesce(var.ami_id, "")) != ""
    )
    error_message = "AWS VM foundations require ami_id when any AWS node group is declared."
  }
}

check "aws_bootstrap_template_path_exists" {
  assert {
    condition = (
      local.normalized_bootstrap_path == "" ||
      fileexists(local.normalized_bootstrap_path)
    )
    error_message = "bootstrap_template_path must point to an existing AWS bootstrap template file when set."
  }
}
