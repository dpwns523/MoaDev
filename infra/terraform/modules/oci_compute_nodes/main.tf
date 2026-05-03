terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0, < 6.0.0"
    }
  }
}

locals {
  oci_worker_node_groups = {
    for name, node_group in var.cluster_topology.node_groups :
    name => node_group if node_group.provider == "oci" && node_group.role == "worker"
  }

  normalized_bootstrap_path      = trimspace(coalesce(var.bootstrap_template_path, ""))
  normalized_ssh_authorized_keys = trimspace(coalesce(var.ssh_authorized_keys, "")) == "" ? null : trimspace(var.ssh_authorized_keys)
  oci_instance_resources_enabled = (
    trimspace(coalesce(var.image_ocid, "")) != "" &&
    trimspace(coalesce(var.compartment_ocid, "")) != "" &&
    length(var.worker_subnet_bindings) > 0
  )

  node_group_plan = {
    for name, node_group in local.oci_worker_node_groups :
    name => {
      provider                  = "oci"
      role                      = node_group.role
      desired_count             = node_group.desired_count
      min_count                 = node_group.min_count
      max_count                 = node_group.max_count
      scaling_strategy          = node_group.scaling_strategy
      worker_shape              = var.worker_shape
      worker_ocpus              = var.worker_ocpus
      worker_memory_gbs         = var.worker_memory_gbs
      boot_volume_gbs           = var.worker_boot_volume_gbs
      subnet_bindings           = var.worker_subnet_bindings
      workload_placement_intent = var.workload_placement_intent
      worker_placement_intent   = var.worker_placement_intent
      storage_class             = var.storage_class
      labels                    = var.labels
      resource_name_prefix      = format("%s-%s", var.name_prefix, name)
    }
  }

  worker_instance_plan = merge({}, [
    for name, node_group in local.node_group_plan : {
      for index in range(node_group.desired_count) :
      format("%s-%02d", node_group.resource_name_prefix, index + 1) => merge(node_group, {
        node_group_name = name
        instance_name   = format("%s-%02d", node_group.resource_name_prefix, index + 1)
        ordinal         = index + 1
        subnet_id = (
          length(node_group.subnet_bindings) == 0
          ? null
          : node_group.subnet_bindings[index % length(node_group.subnet_bindings)].subnet_id
        )
        availability_domain = (
          length(node_group.subnet_bindings) == 0
          ? null
          : node_group.subnet_bindings[index % length(node_group.subnet_bindings)].availability_domain
        )
        bootstrap_user_data = (
          local.normalized_bootstrap_path != "" && fileexists(local.normalized_bootstrap_path)
          ? templatefile(local.normalized_bootstrap_path, {
            cluster_name              = var.cluster_topology.cluster_name
            kubernetes_version        = var.cluster_topology.kubernetes_version
            node_group_name           = name
            node_role                 = node_group.role
            instance_name             = format("%s-%02d", node_group.resource_name_prefix, index + 1)
            storage_class             = var.storage_class
            placement_intent          = var.worker_placement_intent
            workload_placement_intent = var.workload_placement_intent
            cloud_provider            = "oci"
          })
          : <<-EOT
            #cloud-config
            write_files:
              - path: /etc/moadev/node-profile.env
                permissions: "0644"
                content: |
                  MOADEV_CLUSTER_NAME=${var.cluster_topology.cluster_name}
                  MOADEV_KUBERNETES_VERSION=${var.cluster_topology.kubernetes_version}
                  MOADEV_NODE_GROUP=${name}
                  MOADEV_NODE_ROLE=${node_group.role}
                  MOADEV_INSTANCE_NAME=${format("%s-%02d", node_group.resource_name_prefix, index + 1)}
                  MOADEV_STORAGE_CLASS=${var.storage_class}
                  MOADEV_WORKLOAD_PLACEMENT_INTENT=${var.workload_placement_intent}
                  MOADEV_NETWORK_PLACEMENT_INTENT=${var.worker_placement_intent}
            runcmd:
              - [ bash, -lc, "echo 'TODO: replace placeholder bootstrap with Kubespray or host bootstrap workflow' >/etc/motd" ]
          EOT
        )
      })
    }
  ]...)
}

resource "oci_core_instance" "worker" {
  for_each = local.oci_instance_resources_enabled ? local.worker_instance_plan : {}

  availability_domain = each.value.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = each.value.instance_name
  shape               = each.value.worker_shape

  dynamic "shape_config" {
    for_each = length(regexall("Flex", each.value.worker_shape)) > 0 ? [1] : []

    content {
      ocpus         = each.value.worker_ocpus
      memory_in_gbs = each.value.worker_memory_gbs
    }
  }

  create_vnic_details {
    assign_public_ip = false
    display_name     = format("%s-vnic", each.value.instance_name)
    hostname_label   = replace(substr(lower(each.value.instance_name), 0, 63), "/[^a-z0-9-]/", "-")
    nsg_ids          = var.worker_nsg_ids
    subnet_id        = each.value.subnet_id
  }

  metadata = merge(
    {
      user_data = base64encode(each.value.bootstrap_user_data)
    },
    local.normalized_ssh_authorized_keys == null ? {} : {
      ssh_authorized_keys = local.normalized_ssh_authorized_keys
    }
  )

  source_details {
    boot_volume_size_in_gbs = each.value.boot_volume_gbs
    source_id               = var.image_ocid
    source_type             = "image"
  }

  freeform_tags = merge(each.value.labels, {
    Name           = each.value.instance_name
    ClusterName    = var.cluster_topology.cluster_name
    KubernetesRole = each.value.role
    NodeGroup      = each.value.node_group_name
    StorageClass   = each.value.storage_class
    ManagedBy      = "terraform"
  })
}

check "oci_worker_groups_have_subnets" {
  assert {
    condition     = length(local.oci_worker_node_groups) == 0 || length(var.worker_subnet_bindings) > 0
    error_message = "OCI worker node groups require at least one worker subnet reference."
  }
}

check "oci_volume_sizes_are_positive" {
  assert {
    condition     = var.worker_boot_volume_gbs > 0
    error_message = "OCI worker boot volume size must be positive."
  }
}

check "oci_worker_groups_require_image" {
  assert {
    condition = (
      length(local.oci_worker_node_groups) == 0 ||
      trimspace(coalesce(var.image_ocid, "")) != ""
    )
    error_message = "OCI VM foundations require image_ocid when any OCI worker node group is declared."
  }
}

check "oci_worker_groups_have_nsgs" {
  assert {
    condition     = length(local.oci_worker_node_groups) == 0 || length(var.worker_nsg_ids) > 0
    error_message = "OCI worker node groups require explicit NSGs."
  }
}

check "oci_bootstrap_template_path_exists" {
  assert {
    condition = (
      local.normalized_bootstrap_path == "" ||
      fileexists(local.normalized_bootstrap_path)
    )
    error_message = "bootstrap_template_path must point to an existing OCI bootstrap template file when set."
  }
}
