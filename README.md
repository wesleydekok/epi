# EPI Bank — Azure Infrastructure

Terraform-project dat de cloud-infrastructuur voor de EPI Bank demo-omgeving uitrolt op Azure. Het simuleert een gelaagde bankarchitectuur met een publieke frontend, een private API-laag en een afgeschermde database.

---

## Architectuur

```mermaid
graph TD
    Internet((Internet))

    subgraph VNET["Azure VNet — 10.0.0.0/16"]
        direction TB

        subgraph FW_SUB["Firewall Subnet — 10.0.0.0/26"]
            Firewall["🔥 Azure Firewall"]
        end

        subgraph BAS_SUB["Bastion Subnet — 10.0.0.64/27"]
            Bastion["🛡️ Azure Bastion"]
        end

        subgraph PUB_SUB["Public Subnet — 10.0.1.0/24  |  NSG-public"]
            WebVM["🖥️ vm-web\nnginx (port 80/443)\n10.0.1.4"]
        end

        subgraph PRIV_SUB["Private Subnet — 10.0.2.0/24  |  NSG-private"]
            ApiVM["⚙️ vm-api\nFlask API (port 5000)\n10.0.2.4"]
        end

        subgraph DB_SUB["Database Subnet — 10.0.3.0/24  |  NSG-database"]
            Database["🗄️ Azure SQL / Table Storage"]
        end
    end

    KeyVault["🔑 Azure Key Vault"]

    Internet -->|"HTTP/HTTPS"| Firewall
    Firewall -->|DNAT| WebVM
    Bastion -->|SSH| WebVM
    Bastion -->|SSH| ApiVM
    WebVM -->|"/api/ proxy"| ApiVM
    ApiVM -->|"port 1433 / Table API"| Database
    ApiVM -->|"GET secret"| KeyVault
```

---

## Modules

| Module | Beschrijving |
|---|---|
| `vnet` | Virtual Network + 5 subnetten |
| `nsg` | Network Security Groups per subnet |
| `firewall` | Azure Firewall met DNAT-regel voor inkomend verkeer |
| `bastion` | Azure Bastion voor veilige SSH-toegang zonder publiek IP |
| `vms` | Web VM (nginx) en API VM (Flask) |
| `database` | Azure SQL / Table Storage |
| `keyvault` | Key Vault voor SSH-sleutels en connection strings |
| `policy` | Azure Policy voor compliance |

---

## Netwerk

| Subnet | CIDR | Doel |
|---|---|---|
| AzureFirewallSubnet | 10.0.0.0/26 | Azure Firewall (verplichte naam) |
| AzureBastionSubnet | 10.0.0.64/27 | Azure Bastion (verplichte naam) |
| public-subnet | 10.0.1.0/24 | Web VM (frontend) |
| private-subnet | 10.0.2.0/24 | API VM (backend) |
| database-subnet | 10.0.3.0/24 | Database |

---

## Variabelen

| Variabele | Default | Beschrijving |
|---|---|---|
| `location` | `westeurope` | Azure regio |
| `resource_group_name` | `epi` | Naam van de resource group |
| `bastion_subnet_prefix` | `10.0.0.64/27` | CIDR van het Bastion-subnet (gebruikt in NSG-regels) |
| `web_vm_private_ip` | `10.0.1.4` | Privé-IP van de web VM (gebruikt in Firewall DNAT) |

---

## Deployen

```bash
# Initialiseren
terraform init

# Controleer wat er aangemaakt wordt
terraform plan

# Uitrollen
terraform apply
```
