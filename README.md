# Azure AKS Private Cluster Module (AKS + App Gateway Ingress + Key Vault)

Deploy a secure, **private** Azure Kubernetes Service (AKS) cluster with:

- **Application Gateway** (WAF_v2) and **AKS Application Gateway Ingress Controller (AGIC) add-on**
- **Azure Key Vault** with **Private Endpoint** + **Private DNS zone group**
- **Log Analytics** integration for cluster diagnostics/monitoring

> Designed for enterprise environments where **Private DNS zones** and shared resources (DNS + Log Analytics) live in a **separate subscription**.

---

## What this module creates

**Core**
- Resource Group (module-managed)
- AKS (private cluster)
- User-assigned identity for AKS
- Role assignments needed for subnet/DNS access

**Ingress**
- Application Gateway (WAF_v2) + Public IP
- AKS AGIC add-on wired to the gateway
- RBAC so the AGIC identity can manage App Gateway + subnet

**Secrets**
- Azure Key Vault
- Key Vault Private Endpoint (Private Link)
- Private DNS Zone Group association to the shared Key Vault Private DNS zone
- (Optional) AKS Key Vault Secrets Provider add-on + RBAC

**Observability**
- Diagnostic settings sending cluster logs/metrics to Log Analytics

---

## Architecture

```text
Internet
  |
  v
[Public IP] -> [Application Gateway (WAF_v2)]
                      |
                      v
           [AKS (Private Cluster)]
                |         |
                |         +--> [Key Vault Secrets Provider (optional)]
                |
                +--> Private DNS (AKS zone)  (shared subscription)
Key Vault (Private Endpoint) --> Private DNS (vaultcore) (shared subscription)
Logs --> Log Analytics Workspace (shared subscription)
```

---

## Prerequisites

### Networking
- Existing VNet with dedicated subnets for:
  - AKS nodes
  - AKS pods (if using separate pod subnet)
  - Application Gateway
  - Key Vault Private Endpoint
- If using `outbound_type = userDefinedRouting`, your UDR + firewall/NVA egress must be configured **before** cluster creation.

### Shared services (often in another subscription)
- AKS private DNS zone: `privatelink.<region>.azmk8s.io`
- Key Vault private DNS zone: `privatelink.vaultcore.azure.net`
- Log Analytics Workspace

### Permissions (Terraform identity)
Your Terraform principal typically needs:

- **On the subscription where AKS is deployed**
  - `Owner` (or equivalent) so Terraform can create resources and assign RBAC on subnets/AppGW/Key Vault.

- **On the shared DNS resource group** (hosting Private DNS zones)
  - `Reader`
  - Private DNS zone record management role (org-specific)
  - **User Access Administrator** (so Terraform can grant the AKS identity access to the shared DNS zones)

- **On the shared Log Analytics resource group**
  - `Reader`
  - Log Analytics write permissions (org-specific)

Your original module README described this shared-access model; keep those assignments in place when deploying across subscriptions. îˆ€fileciteîˆ‚turn12file0îˆ

---

## Usage

### Minimal example (required inputs only)

> Optional inputs have defaults. This example supplies only variables that have **no default**.

```hcl
module "aks" {
  source = "./modules/aks"

  app_name    = "sbx3"
  environment = "dev"

  # Networking lookups
  virtual_network_name = "vnet-hub-eastus-dev"
  virtual_network_rg   = "rg-network-eastus-dev"

  node_subnet_name     = "snet-aks-nodes"
  pod_subnet_name      = "snet-aks-pods"
  agic_subnet_name     = "snet-appgw"
  keyvault_subnet_name = "snet-kv-pe"

  # AKS
  kubernetes_version = "1.29.7"
  vm_size            = "Standard_D4s_v5"
  zones              = ["1", "2", "3"]

  # App Gateway
  agic_frontend_private_ip = "10.10.8.10"
}
```

### Recommended: pin provider version
Your `providers.tf` pins AzureRM already. Keep the root module aligned:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.57.0"
    }
  }
}
```

---

## Inputs

**Legend**
- **Required**: no default configured in `variables.tf`
- **Optional**: has a default (you can override)

| Name | Type | Required | Default | Description | Notes |
|---|---|---|---|---|---|
| `agic_frontend_private_ip` | string | Yes |  | Static private frontend IP for Application Gateway (must be in the AGIC subnet). |  |
| `agic_subnet_name` | string | Yes |  | Subnet name where the Application Gateway will be deployed. |  |
| `app_name` | string | Yes |  | Short application/workload name used in resource naming. |  |
| `environment` | string | Yes |  | Environment identifier (e.g., dev, test, prod). |  |
| `keyvault_subnet_name` | string | Yes |  | Subnet name used for the Key Vault private endpoint. |  |
| `kubernetes_version` | string | Yes |  | AKS Kubernetes version (e.g., 1.29.7). |  |
| `node_subnet_name` | string | Yes |  | Subnet name for AKS node pool. |  |
| `pod_subnet_name` | string | Yes |  | Subnet name for AKS pod subnet (used with Azure CNI / pod_subnet_id). |  |
| `resource_group_name` | string | Yes |  |  | Currently **unused** (module creates its own RG). Kept for future compatibility. |
| `virtual_network_name` | string | Yes |  | Name of the existing VNet that contains AKS/AppGW/KeyVault subnets. |  |
| `virtual_network_rg` | string | Yes |  | Resource group name where the existing VNet is located. |  |
| `vm_size` | string | Yes |  | VM SKU for the system node pool (e.g., Standard_D4s_v5). |  |
| `zones` | list(string) | Yes |  | Availability zones for node pool and AppGW. |  |
| `admin_group_object_ids` | list(string) | No | [] | AAD group object IDs that will be AKS cluster admins (AAD RBAC). |  |
| `azure_policy_enabled` | bool | No | true | Enable Azure Policy add-on for AKS. |  |
| `azure_rbac_enabled` | bool | No | true | Enable Azure RBAC integration for Kubernetes authorization. |  |
| `dns_service_ip` | string | No | "172.20.0.10" | DNS service IP within service_cidr. |  |
| `enable_agic_addon` | bool | No | true | Enable AGIC add-on and post-create RBAC for the AGIC identity. |  |
| `enable_auto_scaling` | bool | No | true | Enable cluster autoscaler for the default node pool. |  |
| `enable_key_vault_secrets_provider` | bool | No | true | Enable AKS Key Vault Secrets Provider (CSI) and RBAC on the vault for its identity. |  |
| `keyvault_admin_group_object_id` | string | No | "3e52e9c8-5c22-4666-979b-06cf1238ec7b" | AAD group object ID to be granted Key Vault Administrator on the vault scope. |  |
| `load_balancer_sku` | string | No | "standard" | Load balancer SKU for AKS. |  |
| `location` | string | No | "eastus" | Azure region for all resources created by this module. |  |
| `max_count` | number | No | 5 | Maximum node count when autoscaling is enabled. |  |
| `max_pods` | number | No | 50 | Maximum number of pods per node. |  |
| `max_surge` | string | No | "10%" | Max surge for node pool upgrades. |  |
| `min_count` | number | No | 2 | Minimum node count when autoscaling is enabled. |  |
| `network_plugin` | string | No | "azure" | Network plugin for AKS. |  |
| `node_pool_name` | string | No | "system" | Name of the system node pool. |  |
| `node_type` | string | No | "VirtualMachineScaleSets" | AKS node pool type. |  |
| `only_critical_addons_enabled` | bool | No | false | Taint the default node pool with `CriticalAddonsOnly=true:NoSchedule`. | Requires a separate node pool for AGIC and workloads without a matching toleration. Changing this value rotates the default node pool. |
| `os_sku` | string | No | "AzureLinux" | OS SKU for node pool. |  |
| `outbound_type` | string | No | "loadBalancer" | Outbound routing type for AKS. |  |
| `post_aks_wait_seconds` | number | No | 60 | Seconds to wait after AKS creation before applying RBAC to addon-created identities. |  |
| `private_cluster_enabled` | bool | No | true | Enable AKS private cluster. |  |
| `private_cluster_public_fqdn_enabled` | bool | No | false | Enable public FQDN for private cluster. |  |
| `rbac_propagation_wait_seconds` | number | No | 180 | Seconds to wait after pre-AKS role assignments to mitigate RBAC eventual consistency. |  |
| `role_based_access_control_enabled` | bool | No | true | Enable Kubernetes RBAC. |  |
| `secret_rotation_enabled` | bool | No | true | Enable Key Vault Secrets Provider secret rotation. |  |
| `service_cidr` | string | No | "172.20.0.0/16" | CIDR for Kubernetes services. |  |
| `sku_tier` | string | No | "Standard" | AKS SKU tier. |  |
| `tags` | map(string) | No | {} | Tags applied to resources created by this module. |  |
| `temporary_name_for_rotation` | string | No | "temp" | Temporary node pool name used for rotation. |  |
| `waf_firewall_enabled` | bool | No | false | Enable WAF on Application Gateway. |  |
| `waf_firewall_mode` | string | No | "Detection" | WAF mode for Application Gateway. |  |
| `workload_identity_enabled` | bool | No | false | Enable workload identity for AKS. |  |


> **Note:** `resource_group_name` is currently declared but **not used** by the module (the module creates its own RG). It is retained for future compatibility.

---

## Outputs

| Name | Description |
|---|---|
| `aks_id` | Resource ID of the AKS cluster. |
| `aks_fqdn` | FQDN of the AKS cluster. |
| `aks_version` | Version of the AKS cluster. |
| `aks_private_fqdn` | Private FQDN of the AKS cluster. |
| `aks_portal_fqdn` | Portal FQDN of the AKS cluster. |
| `aks_appgw_ingress_controller` | Application Gateway Ingress Controller. |


---

## Common operational notes

### Optional system node pool isolation
Set `only_critical_addons_enabled = true` in the module call to reserve the default node pool for pods that tolerate `CriticalAddonsOnly=true:NoSchedule`. The default is `false`, so existing callers retain the previous scheduling behavior when they omit this input.

This module creates only the default node pool. When enabling this option, callers must provision a separate user node pool for AGIC (enabled by default) and application workloads without a matching toleration. For existing clusters, provision the user pool and migrate these workloads before enabling the taint. Changing this input rotates the default node pool using `temporary_name_for_rotation`.

### AKS create timeouts (90â€“120+ minutes)
When AKS hangs in `Creating`, the most common root causes are environmental:
- outbound egress blocked (when using UDR)
- private DNS zone link/permissions issues
- subnet NSG/UDR blocking bootstrap traffic

Tip: check Azure Activity Log for the AKS resource for the real failure reason.

### Key Vault soft-delete name collisions
Key Vault names are globally unique and soft-delete can block re-creation.
If you repeatedly create/destroy environments, consider adding a suffix or enabling auto-recovery in the root provider features.

---

## Versioning & Compatibility
- Terraform: 1.6+
- AzureRM Provider: 4.57.0 (pinned)

---

## Contributing
- Run `terraform fmt -recursive`
- Run `terraform validate`
- Prefer variable defaults for sensible â€œgolden pathâ€ behavior; document when changing inputs will force replacement (AKS network settings often do).
