variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Canada Central"
}

variable "project_name" {
  description = "Project name used for Azure resources"
  type        = string
  default     = "proshop"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "aks_node_count" {
  description = "Number of AKS worker nodes"
  type        = number
  default     = 1
}

variable "aks_vm_size" {
  description = "AKS worker-node virtual machine size"
  type        = string
  default     = "Standard_D2s_v5"
}
variable "jenkins_admin_username" {
  description = "Administrator username for Jenkins VM"
  type        = string
  default     = "azureuser"
}

variable "jenkins_ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
}