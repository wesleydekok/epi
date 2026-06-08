# Network Interface — Web VM (public subnet)
resource "azurerm_network_interface" "web" {
  name                = "nic-web"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "web-ipconfig"
    subnet_id                     = var.subnet_public_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.web_vm_private_ip
  }
}

# Network Interface — API VM (private subnet)
resource "azurerm_network_interface" "api" {
  name                = "nic-api"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "api-ipconfig"
    subnet_id                     = var.subnet_private_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Web VM — simuleert de bank frontend
resource "azurerm_linux_virtual_machine" "web" {
  name                  = "vm-web"
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = "Standard_D2als_v6"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.web.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/scripts/web_init.sh", {
    api_key = var.api_key
  }))

  lifecycle {
    ignore_changes = [custom_data]
  }
}

# API VM — simuleert de bank backend/API laag
resource "azurerm_linux_virtual_machine" "api" {
  name                  = "vm-api"
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = "Standard_D2als_v6"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.api.id]

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/scripts/api_init.sh", {
    key_vault_name = var.key_vault_name
    api_key        = var.api_key
  }))

  lifecycle {
    ignore_changes = [custom_data]
  }
}

resource "azurerm_key_vault_access_policy" "api_vm" {
  key_vault_id = var.key_vault_id
  tenant_id    = azurerm_linux_virtual_machine.api.identity[0].tenant_id
  object_id    = azurerm_linux_virtual_machine.api.identity[0].principal_id

  secret_permissions = ["Get"]
}