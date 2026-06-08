# modules/database/main.tf

data "http" "my_ip" {
  url = "https://api.ipify.org"
}

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

  public_network_access_enabled = true

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [var.subnet_database_id, var.subnet_private_id]
    ip_rules                   = [data.http.my_ip.response_body]
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

# Sample rekeningen
resource "azurerm_storage_table_entity" "account_1" {
  storage_table_id = azurerm_storage_table.accounts.id
  partition_key    = "NL"
  row_key          = "NL91ABNA0417164300"
  entity = {
    Naam           = "Jan de Vries"
    Rekeningnummer = "NL91ABNA0417164300"
    Saldo          = "4250.75"
    Type           = "Betaalrekening"
  }
}

resource "azurerm_storage_table_entity" "account_2" {
  storage_table_id = azurerm_storage_table.accounts.id
  partition_key    = "NL"
  row_key          = "NL69INGB0123456789"
  entity = {
    Naam           = "Lisa Bakker"
    Rekeningnummer = "NL69INGB0123456789"
    Saldo          = "12830.00"
    Type           = "Spaarrekening"
  }
}

resource "azurerm_storage_table_entity" "account_3" {
  storage_table_id = azurerm_storage_table.accounts.id
  partition_key    = "NL"
  row_key          = "NL58RABO0132394782"
  entity = {
    Naam           = "EPI Bank B.V."
    Rekeningnummer = "NL58RABO0132394782"
    Saldo          = "98450.00"
    Type           = "Zakelijke rekening"
  }
}

# Sample transacties
resource "azurerm_storage_table_entity" "tx_1" {
  storage_table_id = azurerm_storage_table.transactions.id
  partition_key    = "NL91ABNA0417164300"
  row_key          = "20260520-001"
  entity = {
    Datum          = "2026-05-20"
    Omschrijving   = "Salaris mei 2026"
    Bedrag         = "3200.00"
    Type           = "Credit"
    Rekening       = "NL91ABNA0417164300"
  }
}

resource "azurerm_storage_table_entity" "tx_2" {
  storage_table_id = azurerm_storage_table.transactions.id
  partition_key    = "NL91ABNA0417164300"
  row_key          = "20260519-001"
  entity = {
    Datum          = "2026-05-19"
    Omschrijving   = "Albert Heijn"
    Bedrag         = "87.43"
    Type           = "Debet"
    Rekening       = "NL91ABNA0417164300"
  }
}

resource "azurerm_storage_table_entity" "tx_3" {
  storage_table_id = azurerm_storage_table.transactions.id
  partition_key    = "NL91ABNA0417164300"
  row_key          = "20260518-001"
  entity = {
    Datum          = "2026-05-18"
    Omschrijving   = "Huur mei - Van der Berg Vastgoed"
    Bedrag         = "1150.00"
    Type           = "Debet"
    Rekening       = "NL91ABNA0417164300"
  }
}

resource "azurerm_storage_table_entity" "tx_4" {
  storage_table_id = azurerm_storage_table.transactions.id
  partition_key    = "NL91ABNA0417164300"
  row_key          = "20260517-001"
  entity = {
    Datum          = "2026-05-17"
    Omschrijving   = "Tikkie - Etentje vrijdag"
    Bedrag         = "23.50"
    Type           = "Credit"
    Rekening       = "NL91ABNA0417164300"
  }
}

resource "azurerm_storage_table_entity" "tx_5" {
  storage_table_id = azurerm_storage_table.transactions.id
  partition_key    = "NL91ABNA0417164300"
  row_key          = "20260516-001"
  entity = {
    Datum          = "2026-05-16"
    Omschrijving   = "NS Treinabonnement"
    Bedrag         = "109.00"
    Type           = "Debet"
    Rekening       = "NL91ABNA0417164300"
  }
}