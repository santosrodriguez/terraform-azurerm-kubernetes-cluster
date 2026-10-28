 

resource "azurerm_user_assigned_identity" "aks_uai" {
  name                = local.managed_id_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  lifecycle {
    ignore_changes = [ tags ]
  }

}

##############################################
# Pre-AKS RBAC (deterministic, reduces timeouts)
##############################################


resource "azurerm_role_assignment" "aks_node_subnet_netcontrib" {
  scope                = data.azurerm_subnet.aks_node_subnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_uai.principal_id
}

resource "azurerm_role_assignment" "aks_pod_subnet_netcontrib" {
  scope                = data.azurerm_subnet.aks_pod_subnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_uai.principal_id
}

resource "azurerm_role_assignment" "aks_vnet_netcontrib" {
  scope                = data.azurerm_virtual_network.aks_vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_uai.principal_id
}

# Helpful during provisioning: allow the cluster identity to read the gateway resource.
resource "azurerm_role_assignment" "aks_appgw_reader" {
  scope                = azurerm_application_gateway.appgw.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.aks_uai.principal_id
}

# RBAC is eventually consistent; wait to reduce AKS create hangs.
resource "time_sleep" "rbac_propagation" {
  depends_on = [
    azurerm_role_assignment.aks_dns_role_assignment,
    azurerm_role_assignment.aks_node_subnet_netcontrib,
    azurerm_role_assignment.aks_pod_subnet_netcontrib,
    azurerm_role_assignment.aks_vnet_netcontrib,
    azurerm_role_assignment.aks_appgw_reader,
  ]

  create_duration = "${var.rbac_propagation_wait_seconds}s"
}

##############################################
# AKS
##############################################

resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  node_resource_group = "MC_${data.azurerm_resource_group.rg.name}"
  kubernetes_version = var.kubernetes_version
  sku_tier           = var.sku_tier

  private_cluster_enabled             = var.private_cluster_enabled
  private_dns_zone_id                 = data.azurerm_private_dns_zone.aks_privatelink_zone.id
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled
  dns_prefix_private_cluster          = local.aks_name

  azure_policy_enabled              = var.azure_policy_enabled
  role_based_access_control_enabled = var.role_based_access_control_enabled

  local_account_disabled    = true
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_uai.id]
  }

  default_node_pool {
    name                        = var.node_pool_name
    type                        = var.node_type
    vm_size                     = var.vm_size
    zones                       = var.zones
    os_sku                      = var.os_sku
    vnet_subnet_id              = data.azurerm_subnet.aks_node_subnet.id
    pod_subnet_id               = data.azurerm_subnet.aks_pod_subnet.id
    

    max_pods                    = var.max_pods
    auto_scaling_enabled        = var.enable_auto_scaling
    min_count                   = var.min_count
    max_count                   = var.max_count
    only_critical_addons_enabled = var.only_critical_addons_enabled

    temporary_name_for_rotation = var.temporary_name_for_rotation

    upgrade_settings {
      max_surge = var.max_surge
    }
  }

  network_profile {
    network_plugin    = var.network_plugin
    outbound_type     = var.outbound_type
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = var.load_balancer_sku
  }

  azure_active_directory_role_based_access_control {
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = var.azure_rbac_enabled
  }

  oms_agent {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log-sharedsvcseastus.id
  }

  microsoft_defender {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log-sharedsvcseastus.id
  }

  # Plan-safe gating: block exists only if enabled.
  dynamic "ingress_application_gateway" {
    for_each = var.enable_agic_addon ? [1] : []
    content {
      gateway_id = azurerm_application_gateway.appgw.id
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled = true
    }
  }
  lifecycle {
    ignore_changes = [ tags ]
  }



  depends_on = [
    time_sleep.rbac_propagation,
    azurerm_application_gateway.appgw,
  ]

  timeouts {
    create = "120m"
    update = "120m"
    delete = "120m"
  }

}

# Post-AKS wait reduces "principal not found" / AAD replication flakiness.
resource "time_sleep" "post_aks_wait" {
  depends_on      = [azurerm_kubernetes_cluster.aks]
  create_duration = "${var.post_aks_wait_seconds}s"
}

# Diagnostic settings: use enabled_metric (metric is deprecated)
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-aks-${local.name_suffix}"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log-sharedsvcseastus.id

  enabled_metric {
    category = "AllMetrics"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "cloud-controller-manager"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}
