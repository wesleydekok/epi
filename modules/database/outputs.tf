output "storage_account_name" {
  value = azurerm_storage_account.bank.name
}

output "storage_primary_key" {
  value     = azurerm_storage_account.bank.primary_access_key
  sensitive = true
}

output "storage_connection_string" {
  value     = azurerm_storage_account.bank.primary_connection_string
  sensitive = true
}