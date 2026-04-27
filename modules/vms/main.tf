# Network Interface — Web VM (public subnet)
resource "azurerm_network_interface" "web" {
  name                = "nic-web"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "web-ipconfig"
    subnet_id                     = var.subnet_public_id
    private_ip_address_allocation = "Dynamic"
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
  size                  = "Standard_B1s"
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
    offer     = "UbuntuServer"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    echo "<h1>Bank App - Web Frontend</h1>" > /var/www/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOF
  )
}

# API VM — simuleert de bank backend/API laag
resource "azurerm_linux_virtual_machine" "api" {
  name                  = "vm-api"
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.api.id]

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
    offer     = "UbuntuServer"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3-pip
    pip3 install flask azure-data-tables

    cat > /opt/bank_api.py <<'PYEOF'
    from flask import Flask, jsonify
    from azure.data.tables import TableServiceClient

    app = Flask(__name__)

    STORAGE_ACCOUNT = "${var.storage_account_name}"
    STORAGE_KEY      = "${var.storage_primary_key}"

    service = TableServiceClient(
        endpoint=f"https://{STORAGE_ACCOUNT}.table.core.windows.net",
        credential=STORAGE_KEY
    )

    accounts_table     = service.get_table_client("accounts")
    transactions_table = service.get_table_client("transactions")

    @app.route('/api/balance')
    def balance():
        items = list(accounts_table.list_entities())
        return jsonify(items)

    @app.route('/api/transactions')
    def get_transactions():
        items = list(transactions_table.list_entities())
        return jsonify(items)

    if __name__ == '__main__':
        app.run(host='0.0.0.0', port=5000)
    PYEOF

    python3 /opt/bank_api.py &
  EOF
  )
}