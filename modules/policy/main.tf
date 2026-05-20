# Ingebouwde Microsoft policy definities opzoeken via naam.

# AVG: persoonsgegevens moeten versleuteld worden verstuurd (geen HTTP)
data "azurerm_policy_definition" "secure_transfer" {
  display_name = "Secure transfer to storage accounts should be enabled"
}

# AVG: data mag de EU niet verlaten — alleen westeurope toegestaan
data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

# NIS2: SSH (poort 22) en RDP (poort 3389) mogen niet open staan naar internet
data "azurerm_policy_definition" "closed_management_ports" {
  display_name = "Management ports should be closed on your virtual machines"
}

# AVG — verplicht HTTPS op het storage account waar klantdata in staat
resource "azurerm_resource_group_policy_assignment" "secure_transfer" {
  name                 = "secure-transfer"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.secure_transfer.id
}

# AVG — voorkomt dat resources buiten de EU worden aangemaakt
resource "azurerm_resource_group_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_locations
    }
  })
}

# NIS2 — beheerspoorten mogen niet bereikbaar zijn vanaf internet
resource "azurerm_resource_group_policy_assignment" "closed_management_ports" {
  name                 = "closed-management-ports"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.closed_management_ports.id
}
