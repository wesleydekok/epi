# modules/vms/outputs.tf

output "web_private_ip" {
  description = "Privé IP van de web VM"
  value       = azurerm_network_interface.web.private_ip_address
}

output "api_private_ip" {
  description = "Privé IP van de API VM"
  value       = azurerm_network_interface.api.private_ip_address
}