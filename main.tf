terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "vnet" {
  source              = "./modules/vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
}

module "nsg" {
  source              = "./modules/nsg"
  location            = var.location
  resource_group_name = module.vnet.resource_group_name
  subnet_public_id    = module.vnet.subnet_public_id
  subnet_private_id   = module.vnet.subnet_private_id
  subnet_database_id  = module.vnet.subnet_database_id
}

module "firewall" {
  source              = "./modules/firewall"
  location            = var.location
  resource_group_name = module.vnet.resource_group_name
  subnet_firewall_id  = module.vnet.subnet_firewall_id
  subnet_public_id    = module.vnet.subnet_public_id
  subnet_private_id   = module.vnet.subnet_private_id
  subnet_database_id  = module.vnet.subnet_database_id
  web_vm_private_ip   = "10.0.1.4"
}

module "bastion" {
  source              = "./modules/bastion"
  location            = var.location
  resource_group_name = module.vnet.resource_group_name
  subnet_bastion_id   = module.vnet.subnet_bastion_id
}

module "keyvault" {
  source              = "./modules/keyvault"
  location            = var.location
  resource_group_name = module.vnet.resource_group_name
}

module "database" {
  source              = "./modules/database"
  location            = var.location
  resource_group_name = module.vnet.resource_group_name
  subnet_database_id  = module.vnet.subnet_database_id
  subnet_private_id   = module.vnet.subnet_private_id
  key_vault_id        = module.keyvault.key_vault_id
  depends_on          = [module.keyvault]
}

module "policy" {
  source            = "./modules/policy"
  resource_group_id = module.vnet.resource_group_id
}

module "vms" {
  source              = "./modules/vms"
  location            = var.location
  resource_group_name = module.vnet.resource_group_name
  ssh_public_key      = module.keyvault.ssh_public_key
  subnet_public_id    = module.vnet.subnet_public_id
  subnet_private_id   = module.vnet.subnet_private_id
  key_vault_id        = module.keyvault.key_vault_id
  key_vault_name      = module.keyvault.key_vault_name
  depends_on          = [module.keyvault, module.database]
}