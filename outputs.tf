output "web_vm_private_ip" {
  description = "Privé IP van de web VM (public subnet)"
  value       = module.vms.web_private_ip
}

output "api_vm_private_ip" {
  description = "Privé IP van de API VM (private subnet)"
  value       = module.vms.api_private_ip
}

output "firewall_public_ip" {
  description = "Publiek IP van de Azure Firewall"
  value       = module.firewall.firewall_public_ip
}

output "bastion_public_ip" {
  description = "Publiek IP van Azure Bastion"
  value       = module.bastion.bastion_public_ip
}

output "key_vault_name" {
  description = "Naam van de Key Vault"
  value       = module.keyvault.key_vault_name
}

output "storage_account_name" {
  description = "Naam van het Storage Account"
  value       = module.database.storage_account_name
}

output "ssh_private_key" {
  description = "Private SSH key om in te loggen op de VMs"
  value       = module.keyvault.ssh_private_key
  sensitive   = true
}
