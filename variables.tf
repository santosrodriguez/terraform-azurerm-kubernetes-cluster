################################
# General
################################

variable "app_name" {
  type        = string
  description = "Short application/workload name used in resource naming."
}

variable "environment" {
  type        = string
  description = "Environment identifier (e.g., dev, test, prod)."
}

variable "location" {
  type        = string
  description = "Azure region for all resources created by this module."
  default     = "eastus"
}
variable "resource_group_name" {
  type = string
  description = "Name of the resource group"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to resources created by this module."
  default     = {}
}

################################
# Networking (lookups)
################################

variable "virtual_network_name" {
  type        = string
  description = "Name of the existing VNet that contains AKS/AppGW/KeyVault subnets."
}

variable "virtual_network_rg" {
  type        = string
  description = "Resource group name where the existing VNet is located."
}

variable "node_subnet_name" {
  type        = string
  description = "Subnet name for AKS node pool."
}

variable "pod_subnet_name" {
  type        = string
  description = "Subnet name for AKS pod subnet (used with Azure CNI / pod_subnet_id)."
}

variable "agic_subnet_name" {
  type        = string
  description = "Subnet name where the Application Gateway will be deployed."
}

variable "keyvault_subnet_name" {
  type        = string
  description = "Subnet name used for the Key Vault private endpoint."
}

################################
# External Resource IDs
################################
 

################################
# AKS Core Settings
################################

variable "kubernetes_version" {
  type        = string
  description = "AKS Kubernetes version (e.g., 1.29.7)."
}

variable "sku_tier" {
  type        = string
  description = "AKS SKU tier."
  default     = "Standard"
}

variable "private_cluster_enabled" {
  type        = bool
  description = "Enable AKS private cluster."
  default     = true
}

variable "private_cluster_public_fqdn_enabled" {
  type        = bool
  description = "Enable public FQDN for private cluster."
  default     = false
}

variable "azure_policy_enabled" {
  type        = bool
  description = "Enable Azure Policy add-on for AKS."
  default     = true
}

variable "role_based_access_control_enabled" {
  type        = bool
  description = "Enable Kubernetes RBAC."
  default     = true
}

variable "azure_rbac_enabled" {
  type        = bool
  description = "Enable Azure RBAC integration for Kubernetes authorization."
  default     = true
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "AAD group object IDs that will be AKS cluster admins (AAD RBAC)."
  default     = []
}

variable "workload_identity_enabled" {
  type        = bool
  description = "Enable workload identity for AKS."
  default     = false
}

################################
# Node Pool
################################

variable "node_pool_name" {
  type        = string
  description = "Name of the system node pool."
  default     = "system"
}

variable "node_type" {
  type        = string
  description = "AKS node pool type."
  default     = "VirtualMachineScaleSets"
}

variable "only_critical_addons_enabled" {
  type        = bool
  description = "Taint the default node pool with CriticalAddonsOnly=true:NoSchedule. When enabled, callers must provide a separate node pool for AGIC and workloads without a matching toleration. Changing this value rotates the default node pool."
  default     = false
}

variable "vm_size" {
  type        = string
  description = "VM SKU for the system node pool (e.g., Standard_D4s_v5)."
}

variable "zones" {
  type        = list(string)
  description = "Availability zones for node pool and AppGW."

}

variable "os_sku" {
  type        = string
  description = "OS SKU for node pool."
  default     = "AzureLinux"
}



variable "min_count" {
  type        = number
  description = "Minimum node count when autoscaling is enabled."
  default     = 2
}

variable "max_count" {
  type        = number
  description = "Maximum node count when autoscaling is enabled."
  default     = 5
}

variable "max_pods" {
  type        = number
  description = "Maximum number of pods per node."
  default     = 50
}

variable "max_surge" {
  type        = string
  description = "Max surge for node pool upgrades."
  default     = "10%"
}

variable "temporary_name_for_rotation" {
  type        = string
  description = "Temporary node pool name used for rotation."
  default     = "temp"
}

################################
# Network Profile
################################

variable "network_plugin" {
  type        = string
  description = "Network plugin for AKS."
  default     = "azure"
}

variable "outbound_type" {
  type        = string
  description = "Outbound routing type for AKS."
  default     = "userDefinedRouting"
}


variable "service_cidr" {
  type        = string
  description = "CIDR for Kubernetes services."
  default     = "172.20.0.0/16"
}

variable "dns_service_ip" {
  type        = string
  description = "DNS service IP within service_cidr."
  default     = "172.20.0.10"
}

variable "load_balancer_sku" {
  type        = string
  description = "Load balancer SKU for AKS."
  default     = "standard"
}

################################
# Feature Gates (plan-safe)
################################

variable "enable_agic_addon" {
  type        = bool
  description = "Enable AGIC add-on and post-create RBAC for the AGIC identity."
  default     = true
}

variable "enable_key_vault_secrets_provider" {
  type        = bool
  description = "Enable AKS Key Vault Secrets Provider (CSI) and RBAC on the vault for its identity."
  default     = true
}

variable "secret_rotation_enabled" {
  type        = bool
  description = "Enable Key Vault Secrets Provider secret rotation."
  default     = true
}
variable "enable_auto_scaling" {
  type        = bool
  description = "Enable cluster autoscaler for the default node pool."
  default     = true
}
################################
# Application Gateway / AGIC
################################

variable "agic_frontend_private_ip" {
  type        = string
  description = "Static private frontend IP for Application Gateway (must be in the AGIC subnet)."
}

variable "waf_firewall_enabled" {
  type        = bool
  description = "Enable WAF on Application Gateway."
  default     = false
}

variable "waf_firewall_mode" {
  type        = string
  description = "WAF mode for Application Gateway."
  default     = "Detection"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_firewall_mode)
    error_message = "waf_firewall_mode must be Detection or Prevention."
  }
}

################################
# Key Vault (Azure RBAC)
################################

variable "keyvault_admin_group_object_id" {
  type        = string
  description = "AAD group object ID to be granted Key Vault Administrator on the vault scope."
  default = "3e52e9c8-5c22-4666-979b-06cf1238ec7b"
}
 

################################
# Timing / Hardening
################################

variable "rbac_propagation_wait_seconds" {
  type        = number
  description = "Seconds to wait after pre-AKS role assignments to mitigate RBAC eventual consistency."
  default     = 180
}

variable "post_aks_wait_seconds" {
  type        = number
  description = "Seconds to wait after AKS creation before applying RBAC to addon-created identities."
  default     = 60
}


## DNS
variable "private_dns_zone_resource_group" {
  type        = string
  description = "Private DNS zone resource group. "
  default = "rg-azuredns-prd-01"
}

variable "aks_private_dns_zone_name" {
  type        = string
  description = "AKS private DNS zone name."
  default = "privatelink.eastus.azmk8s.io"
}

variable "keyvault_private_dns_zone_name" {
  type        = string
  description = "Keyvault private DNS zone name."
  default = "privatelink.vaultcore.azure.net"
}

variable "log_analytics_workspace_resource_group" {
  type        = string
  description = "Log analytics workspace resource group."
  default = "logs_rg"

}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Log analytics workspace name."
  default = "log-sharedsvcseastus"

}
