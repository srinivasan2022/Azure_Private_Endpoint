terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.1.0"
    }
  }
}

provider "azurerm" {
  features {
  }
}

resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

module "resource-group" {
  source   = "../modules/resource_group"
  rg_name  = "pv-rg"
  location = "West US"
}

module "network" {
  source = "../modules/network"
  vnet_name = "pv-vnet"
  rg_name = module.resource-group.rg_name
  location = module.resource-group.rg_location
  subnet_name = "subnet1"
  depends_on = [ module.resource-group ]
}

module "vm" {
  source = "../modules/vm"
  vm_name = "pv-vm"
  rg_name = module.resource-group.rg_name
  location = module.resource-group.rg_location
  subnet_id = module.network.subnet_id
  depends_on = [ module.network ]
}

module "storage" {
  source = "../modules/storage"
  storage_account_name = "pvtstacc${random_string.random.result}"
  rg_name = module.resource-group.rg_name
  location = module.resource-group.rg_location
  vnet_id = module.network.vnet_id
  subnet_id = module.network.subnet_id
  depends_on = [ module.network ]

}
