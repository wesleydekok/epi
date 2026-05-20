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

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx

    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="nl">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>EPI Bank</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #f0f2f5; color: #333; }
        header {
          background: #1a3c5e;
          color: white;
          padding: 16px 32px;
          display: flex;
          align-items: center;
          gap: 12px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        }
        header h1 { font-size: 1.4rem; font-weight: 600; }
        header span { font-size: 1.8rem; }
        .container { max-width: 900px; margin: 40px auto; padding: 0 20px; }
        .welcome {
          background: white;
          border-radius: 12px;
          padding: 28px;
          margin-bottom: 24px;
          box-shadow: 0 2px 6px rgba(0,0,0,0.06);
        }
        .welcome h2 { font-size: 1.2rem; color: #1a3c5e; margin-bottom: 8px; }
        .welcome p { color: #666; font-size: 0.95rem; }
        .cards { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 24px; }
        .card {
          background: white;
          border-radius: 12px;
          padding: 24px;
          box-shadow: 0 2px 6px rgba(0,0,0,0.06);
          cursor: pointer;
          transition: transform 0.15s, box-shadow 0.15s;
          text-decoration: none;
          color: inherit;
          display: block;
        }
        .card:hover { transform: translateY(-2px); box-shadow: 0 6px 16px rgba(0,0,0,0.1); }
        .card-icon { font-size: 2rem; margin-bottom: 12px; }
        .card h3 { font-size: 1rem; color: #1a3c5e; margin-bottom: 6px; }
        .card p { font-size: 0.85rem; color: #888; }
        .status {
          background: white;
          border-radius: 12px;
          padding: 20px 28px;
          box-shadow: 0 2px 6px rgba(0,0,0,0.06);
          display: flex;
          align-items: center;
          gap: 10px;
          font-size: 0.9rem;
          color: #555;
        }
        .dot { width: 10px; height: 10px; border-radius: 50%; background: #2ecc71; display: inline-block; }
        #balance-section, #transactions-section {
          background: white;
          border-radius: 12px;
          padding: 24px;
          margin-top: 24px;
          box-shadow: 0 2px 6px rgba(0,0,0,0.06);
          display: none;
        }
        #balance-section h3, #transactions-section h3 {
          color: #1a3c5e;
          margin-bottom: 16px;
          font-size: 1rem;
        }
        table { width: 100%; border-collapse: collapse; font-size: 0.9rem; }
        th { text-align: left; padding: 10px 12px; background: #f8f9fa; color: #555; font-weight: 600; border-bottom: 2px solid #e9ecef; }
        td { padding: 10px 12px; border-bottom: 1px solid #f0f0f0; }
        tr:last-child td { border-bottom: none; }
        .loading { color: #aaa; font-size: 0.9rem; }
        .error { color: #e74c3c; font-size: 0.9rem; }
      </style>
    </head>
    <body>
      <header>
        <span>🏦</span>
        <h1>EPI Bank — Online Bankieren</h1>
      </header>
      <div class="container">
        <div class="welcome">
          <h2>Welkom bij EPI Bank</h2>
          <p>Beheer uw rekeningen en transacties via ons beveiligde platform.</p>
        </div>
        <div class="cards">
          <a class="card" onclick="loadBalance(); return false;" href="#">
            <div class="card-icon">💰</div>
            <h3>Rekeningen</h3>
            <p>Bekijk uw saldo en rekeninggegevens</p>
          </a>
          <a class="card" onclick="loadTransactions(); return false;" href="#">
            <div class="card-icon">📋</div>
            <h3>Transacties</h3>
            <p>Overzicht van uw recente betalingen</p>
          </a>
        </div>
        <div class="status">
          <span class="dot"></span>
          Alle systemen operationeel
        </div>
        <div id="balance-section">
          <h3>💰 Rekeningen</h3>
          <div id="balance-content" class="loading">Laden...</div>
        </div>
        <div id="transactions-section">
          <h3>📋 Transacties</h3>
          <div id="transactions-content" class="loading">Laden...</div>
        </div>
      </div>
      <script>
        const API = '';

        function renderTable(data, section, content) {
          document.getElementById(section).style.display = 'block';
          if (!data.length) {
            document.getElementById(content).innerHTML = '<p style="color:#aaa">Geen gegevens gevonden.</p>';
            return;
          }
          const keys = Object.keys(data[0]).filter(k => !['PartitionKey','RowKey','etag','Timestamp'].includes(k));
          let html = '<table><tr>' + keys.map(k => '<th>' + k + '</th>').join('') + '</tr>';
          data.forEach(row => {
            html += '<tr>' + keys.map(k => '<td>' + (row[k] ?? '') + '</td>').join('') + '</tr>';
          });
          document.getElementById(content).innerHTML = html + '</table>';
        }

        function loadBalance() {
          fetch(API + '/api/balance')
            .then(r => r.json())
            .then(d => renderTable(d, 'balance-section', 'balance-content'))
            .catch(() => {
              document.getElementById('balance-section').style.display = 'block';
              document.getElementById('balance-content').innerHTML = '<p class="error">Kon geen verbinding maken met de API.</p>';
            });
        }

        function loadTransactions() {
          fetch(API + '/api/transactions')
            .then(r => r.json())
            .then(d => renderTable(d, 'transactions-section', 'transactions-content'))
            .catch(() => {
              document.getElementById('transactions-section').style.display = 'block';
              document.getElementById('transactions-content').innerHTML = '<p class="error">Kon geen verbinding maken met de API.</p>';
            });
          }
      </script>
    </body>
    </html>
    HTML

    cat > /etc/nginx/sites-available/default <<'NGINX'
    server {
      listen 80;
      location / {
        root /var/www/html;
        index index.html;
      }
      location /api/ {
        proxy_pass http://10.0.2.4:5000/api/;
        proxy_set_header Host $host;
      }
    }
    NGINX

    systemctl enable nginx
    systemctl restart nginx
  EOF
  )
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

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3-pip jq curl
    pip3 install flask azure-data-tables

    # Wacht tot IMDS beschikbaar is en haal connection string op uit Key Vault
    for i in $(seq 1 12); do
      TOKEN=$(curl -sf -H "Metadata:true" \
        "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net" \
        | jq -r .access_token) && [ "$TOKEN" != "null" ] && break
      sleep 10
    done

    CONN_STR=$(curl -sf \
      -H "Authorization: Bearer $TOKEN" \
      "https://${var.key_vault_name}.vault.azure.net/secrets/storage-connection-string?api-version=7.4" \
      | jq -r .value)

    cat > /opt/bank_api.py <<'PYEOF'
from flask import Flask, jsonify
from azure.data.tables import TableServiceClient
import os

app = Flask(__name__)
service = TableServiceClient.from_connection_string(os.environ["STORAGE_CONN_STR"])
accounts_table     = service.get_table_client("accounts")
transactions_table = service.get_table_client("transactions")

@app.route('/api/balance')
def balance():
    return jsonify(list(accounts_table.list_entities()))

@app.route('/api/transactions')
def get_transactions():
    return jsonify(list(transactions_table.list_entities()))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYEOF

    echo "STORAGE_CONN_STR=$CONN_STR" > /etc/bank_api.env
    chmod 600 /etc/bank_api.env

    cat > /etc/systemd/system/bank-api.service <<'SVCEOF'
[Unit]
Description=Bank API
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/bank_api.py
EnvironmentFile=/etc/bank_api.env
Restart=on-failure
User=nobody

[Install]
WantedBy=multi-user.target
SVCEOF

    systemctl daemon-reload
    systemctl enable bank-api
    systemctl start bank-api
  EOF
  )
}

resource "azurerm_key_vault_access_policy" "api_vm" {
  key_vault_id = var.key_vault_id
  tenant_id    = azurerm_linux_virtual_machine.api.identity[0].tenant_id
  object_id    = azurerm_linux_virtual_machine.api.identity[0].principal_id

  secret_permissions = ["Get"]
}