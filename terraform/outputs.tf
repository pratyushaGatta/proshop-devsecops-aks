output "resource_group_name" {
  description = "Azure resource group name"
  value       = azurerm_resource_group.main.name
}

output "acr_name" {
  description = "Azure Container Registry name"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Azure Container Registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_kubelet_identity_object_id" {
  description = "AKS kubelet managed identity object ID"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "cosmosdb_account_name" {
  description = "Cosmos DB account name"
  value       = azurerm_cosmosdb_account.mongodb.name
}

output "cosmosdb_database_name" {
  description = "MongoDB database name"
  value       = azurerm_cosmosdb_mongo_database.proshop.name
}

output "cosmosdb_mongodb_connection_string" {
  description = "Sensitive MongoDB connection string"
  value       = azurerm_cosmosdb_account.mongodb.primary_mongodb_connection_string
  sensitive   = true

}
output "jenkins_public_ip" {
  description = "Public IP of the Jenkins VM"
  value       = azurerm_public_ip.jenkins.ip_address
}