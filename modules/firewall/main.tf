# Public IP voor Firewall
resource "azurerm_public_ip" "firewall" {
  name                = "pip-firewall"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Azure Firewall
resource "azurerm_firewall" "main" {
  name                = "fw-main"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = var.subnet_firewall_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

# DNAT: stuur inkomend HTTP door naar vm-web
resource "azurerm_firewall_nat_rule_collection" "http_to_web" {
  name                = "dnat-http-to-web"
  azure_firewall_name = azurerm_firewall.main.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Dnat"

  rule {
    name                  = "http-to-vm-web"
    protocols             = ["TCP"]
    source_addresses      = ["*"]
    destination_addresses = [azurerm_public_ip.firewall.ip_address]
    destination_ports     = ["80"]
    translated_address    = var.web_vm_private_ip
    translated_port       = "80"
  }

  rule {
    name                  = "https-to-vm-web"
    protocols             = ["TCP"]
    source_addresses      = ["*"]
    destination_addresses = [azurerm_public_ip.firewall.ip_address]
    destination_ports     = ["443"]
    translated_address    = var.web_vm_private_ip
    translated_port       = "443"
  }
}

# Netwerk regel: sta HTTP/HTTPS toe vanuit VNet
resource "azurerm_firewall_network_rule_collection" "allow_outbound" {
  name                = "allow-outbound"
  azure_firewall_name = azurerm_firewall.main.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "allow-http-https"
    protocols             = ["TCP"]
    source_addresses      = ["10.0.0.0/16"]
    destination_addresses = ["*"]
    destination_ports     = ["80", "443"]
  }
}

# Deny all overige outbound
resource "azurerm_firewall_network_rule_collection" "deny_all" {
  name                = "deny-all"
  azure_firewall_name = azurerm_firewall.main.name
  resource_group_name = var.resource_group_name
  priority            = 200
  action              = "Deny"

  rule {
    name                  = "deny-all"
    protocols             = ["Any"]
    source_addresses      = ["*"]
    destination_addresses = ["*"]
    destination_ports     = ["*"]
  }
}

# Route Table
resource "azurerm_route_table" "main" {
  name                = "rt-via-firewall"
  location            = var.location
  resource_group_name = var.resource_group_name

  depends_on = [azurerm_firewall.main]

  route {
    name                   = "route-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.main.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "public" {
  subnet_id      = var.subnet_public_id
  route_table_id = azurerm_route_table.main.id
}

resource "azurerm_subnet_route_table_association" "private" {
  subnet_id      = var.subnet_private_id
  route_table_id = azurerm_route_table.main.id
}

resource "azurerm_subnet_route_table_association" "database" {
  subnet_id      = var.subnet_database_id
  route_table_id = azurerm_route_table.main.id
}