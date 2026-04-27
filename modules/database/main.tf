# modules/database/main.tf

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "bank" {
  name                     = "bankapp${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Geen publieke toegang
  public_network_access_enabled = false

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [var.subnet_database_id]
  }
}

# Tabel voor rekeningen
resource "azurerm_storage_table" "accounts" {
  name                 = "accounts"
  storage_account_name = azurerm_storage_account.bank.name
}

# Tabel voor transacties
resource "azurerm_storage_table" "transactions" {
  name                 = "transactions"
  storage_account_name = azurerm_storage_account.bank.name
}

# Sla connection string op in Key Vault
resource "azurerm_key_vault_secret" "storage_connection" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.bank.primary_connection_string
  key_vault_id = var.key_vault_id
}