resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  common_tags = {
    Project     = "ProShop DevSecOps"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = local.common_tags
}

resource "azurerm_container_registry" "main" {
  name                = "${var.project_name}acr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku           = "Basic"
  admin_enabled = false

  tags = local.common_tags
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.project_name}-${var.environment}"

  sku_tier = "Free"

  default_node_pool {
    name                 = "system"
    node_count           = var.aks_node_count
    vm_size              = var.aks_vm_size
    auto_scaling_enabled = false
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = local.common_tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_cosmosdb_account" "mongodb" {
  name                = "cosmos-proshop-${random_string.suffix.result}"
  location            = "East US"
  resource_group_name = azurerm_resource_group.main.name

  offer_type = "Standard"
  kind       = "MongoDB"

  mongo_server_version          = "4.2"
  free_tier_enabled             = true
  public_network_access_enabled = true

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = "East US"
    failover_priority = 0
    zone_redundant    = false
  }

  tags = local.common_tags
}

resource "azurerm_cosmosdb_mongo_database" "proshop" {
  name                = "proshop"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.mongodb.name

  throughput = 400
}