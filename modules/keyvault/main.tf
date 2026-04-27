data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_key_vault" "main" {
  name                = "kv-epi-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "Set", "List", "Delete", "Purge"
    ]
  }
}

# SSH key automatisch genereren
resource "tls_private_key" "vm_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Private key opslaan in KeyVault
resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "vm-ssh-private-key"
  value        = tls_private_key.vm_ssh.private_key_pem
  key_vault_id = azurerm_key_vault.main.id
}

# Public key opslaan in KeyVault
resource "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "vm-ssh-public-key"
  value        = tls_private_key.vm_ssh.public_key_openssh
  key_vault_id = azurerm_key_vault.main.id
}