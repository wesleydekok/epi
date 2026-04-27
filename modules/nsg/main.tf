# NSG voor public subnet
resource "azurerm_network_security_group" "public" {
  name                = "nsg-public"
  location            = var.location
  resource_group_name = var.resource_group_name
  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-https"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# NSG voor private subnet
resource "azurerm_network_security_group" "private" {
  name                = "nsg-private"
  location            = var.location
  resource_group_name = var.resource_group_name
  security_rule {
    name                       = "allow-inbound-from-public"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "deny-inbound-internet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}
# NSG voor database subnet
resource "azurerm_network_security_group" "database" {
  name                = "nsg-database"
  location            = var.location
  resource_group_name = var.resource_group_name
  security_rule {
    name                       = "allow-inbound-from-private"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "deny-all-outbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}
# NSGs koppelen aan subnetten
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = var.subnet_public_id
  network_security_group_id = azurerm_network_security_group.public.id
}
resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = var.subnet_private_id
  network_security_group_id = azurerm_network_security_group.private.id
}
resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = var.subnet_database_id
  network_security_group_id = azurerm_network_security_group.database.id
}
