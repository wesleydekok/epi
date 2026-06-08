#!/bin/bash
until curl -sf --max-time 5 http://azure.archive.ubuntu.com/ubuntu/ > /dev/null 2>&1; do
  echo "Wacht op netwerk..."
  sleep 10
done

for i in $(seq 1 5); do
  apt-get update -y && apt-get install -y nginx && break
  echo "apt-get poging $i mislukt, opnieuw over 15 seconden..."
  sleep 15
done

if ! command -v nginx &>/dev/null; then
  echo "ERROR: nginx kon niet worden geinstalleerd na 5 pogingen" >&2
  exit 1
fi

mkdir -p /var/www/html

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

apt-get install -y openssl

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx-selfsigned.key \
  -out /etc/ssl/certs/nginx-selfsigned.crt \
  -subj "/C=NL/ST=Noord-Holland/L=Amsterdam/O=EPI Bank/CN=epibank.local"

cat > /etc/nginx/sites-available/default <<NGINX
server {
  listen 80;
  return 301 https://\$host\$request_uri;
}

server {
  listen 443 ssl;
  ssl_certificate     /etc/ssl/certs/nginx-selfsigned.crt;
  ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

  location / {
    root /var/www/html;
    index index.html;
  }
  location /api/ {
    proxy_pass http://10.0.2.4:5000/api/;
    proxy_set_header Host \$host;
    proxy_set_header X-Internal-Token ${api_key};
  }
}
NGINX

systemctl enable nginx
systemctl restart nginx
