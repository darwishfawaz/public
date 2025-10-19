terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features = {}
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
  default     = "example-rg"
}

variable "location" {
  type        = string
  description = "Azure region for the Resource Group"
  default     = "eastus"
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}