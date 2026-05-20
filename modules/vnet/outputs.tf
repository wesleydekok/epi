output "vnet_id" {
  description = "ID van het VNet"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "subnet_public_id" {
  description = "ID van het public subnet"
  value       = azurerm_subnet.public.id
}

output "subnet_private_id" {
  value = azurerm_subnet.private.id
}

output "subnet_database_id" {
  value = azurerm_subnet.database.id
}

output "subnet_firewall_id" {
  value = azurerm_subnet.firewall.id
}

output "subnet_bastion_id" {
  value = azurerm_subnet.bastion.id
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "resource_group_id" {
  value = azurerm_resource_group.main.id
}