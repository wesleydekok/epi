resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "main" {
  name                = "bastion-main"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"      # ← toevoegen
  tunneling_enabled   = true            # ← native client aanzetten

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = var.subnet_bastion_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}