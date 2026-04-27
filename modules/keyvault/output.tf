output "key_vault_id" {
  value = azurerm_key_vault.main.id
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "ssh_public_key" {
  value = tls_private_key.vm_ssh.public_key_openssh
}

output "ssh_private_key" {
  value     = tls_private_key.vm_ssh.private_key_pem
  sensitive = true
}