#!/bin/bash
until curl -sf --max-time 5 http://azure.archive.ubuntu.com/ubuntu/ > /dev/null 2>&1; do
  echo "Wacht op netwerk..."
  sleep 10
done

for i in $(seq 1 5); do
  apt-get update -y && apt-get install -y python3-pip jq curl && break
  echo "apt-get poging $i mislukt, opnieuw over 15 seconden..."
  sleep 15
done

if ! command -v pip3 &>/dev/null; then
  echo "ERROR: python3-pip kon niet worden geinstalleerd na 5 pogingen" >&2
  exit 1
fi

for i in $(seq 1 5); do
  pip3 install flask azure-data-tables && break
  echo "pip3 install poging $i mislukt, opnieuw over 15 seconden..."
  sleep 15
done

if ! python3 -c "import flask" &>/dev/null; then
  echo "ERROR: flask kon niet worden geinstalleerd na 5 pogingen" >&2
  exit 1
fi

for i in $(seq 1 12); do
  TOKEN=$(curl -sf -H "Metadata:true" \
    "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net" \
    | jq -r .access_token) && [ "$TOKEN" != "null" ] && break
  sleep 10
done

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "ERROR: kon geen IMDS-token ophalen na 12 pogingen" >&2
  exit 1
fi

CONN_STR=$(curl -sf \
  -H "Authorization: Bearer $TOKEN" \
  "https://${key_vault_name}.vault.azure.net/secrets/storage-connection-string?api-version=7.4" \
  | jq -r .value)

if [ -z "$CONN_STR" ] || [ "$CONN_STR" = "null" ]; then
  echo "ERROR: kon geen connection string ophalen uit Key Vault" >&2
  exit 1
fi

cat > /opt/bank_api.py <<'PYEOF'
from flask import Flask, jsonify, request, abort
from azure.data.tables import TableServiceClient
from functools import wraps
import os

app = Flask(__name__)
service = TableServiceClient.from_connection_string(os.environ["STORAGE_CONN_STR"])
API_KEY = os.environ["API_KEY"]
accounts_table     = service.get_table_client("accounts")
transactions_table = service.get_table_client("transactions")

def require_api_key(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if request.headers.get("X-Internal-Token") != API_KEY:
            abort(403)
        return f(*args, **kwargs)
    return wrapper

@app.route('/api/balance')
@require_api_key
def balance():
    return jsonify(list(accounts_table.list_entities()))

@app.route('/api/transactions')
@require_api_key
def get_transactions():
    return jsonify(list(transactions_table.list_entities()))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYEOF

echo "STORAGE_CONN_STR=$CONN_STR" > /etc/bank_api.env
echo "API_KEY=${api_key}" >> /etc/bank_api.env
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
