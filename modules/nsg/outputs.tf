output "nsg_public_id" {
  value = azurerm_network_security_group.public.id
}
output "nsg_private_id" {
  value = azurerm_network_security_group.private.id
}
output "nsg_database_id" {
  value = azurerm_network_security_group.database.id
}