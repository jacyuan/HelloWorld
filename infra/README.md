# Infrastructure Scripts

Azure CLI scripts for provisioning and tearing down cloud resources.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- Logged in: `az login`
- Access to the resource group (`RESOURCE_GROUP`) defined in `variables.sh`
  ```bash
  # Verify access
  az group show --name <RESOURCE_GROUP> --output table
  ```

## Structure

```
infra/
├── create.sh                 # Interactive: create one or all resources
├── teardown.sh               # Interactive: tear down one or all resources
├── variables.sh              # Shared configuration (resource names, SKU, region)
├── app-service/
│   ├── create.sh             # Creates App Service Plan + App Service (idempotent)
│   └── teardown.sh           # Deletes App Service + App Service Plan
├── sql/
│   ├── create.sh             # Creates SQL Server + SQL Database (idempotent)
│   ├── grant-access.sh       # Grants Entra principals data-plane access (idempotent)
│   └── teardown.sh           # Deletes SQL Database + SQL Server
├── storage/
│   ├── create.sh             # Creates Storage Account (idempotent)
│   └── teardown.sh           # Deletes Storage Account
├── function/
│   ├── create.sh             # Creates Function App (Consumption, idempotent)
│   └── teardown.sh           # Deletes Function App + orphaned consumption plan
├── keyvault/
│   ├── create.sh             # Creates Key Vault (idempotent, RBAC-enabled)
│   └── teardown.sh           # Soft-deletes Key Vault (optional purge)
└── README.md
```

## Setup

Before running any script, review and edit `variables.sh`. Key variables to check:

- **`AZ_CMD`** — path to the Azure CLI binary. Default is a Windows path (`C:\Tools\azure-cli\bin\az.cmd`). On macOS/Linux, change it to `az`.
- **`RESOURCE_GROUP`** — the Azure resource group all resources are created in. Make sure it exists and you have access.
- **`SQL_ADMIN_USER`** / **`SQL_ADMIN_PASSWORD`** — credentials for SQL Server authentication. The password is empty by default; set it in the file or pass it as an environment variable.
- **`SQL_FIREWALL_RULES`** — IP whitelist for remote database access. Add your IP here if you need to connect from your local machine (format: `"RuleName:StartIP:EndIP"`).

## Usage

```bash
# Interactive: choose which resource to create (or all)
sh infra/create.sh

# Interactive: choose which resource to tear down (or all)
sh infra/teardown.sh

# Or run individually
sh infra/app-service/create.sh
sh infra/sql/create.sh
sh infra/storage/create.sh
sh infra/function/create.sh
sh infra/keyvault/create.sh
sh infra/app-service/teardown.sh
sh infra/sql/teardown.sh
sh infra/storage/teardown.sh
sh infra/function/teardown.sh
sh infra/keyvault/teardown.sh
```

## What the create scripts do

### `create.sh` (interactive)

- Lets you create **all** resources or pick one
- When creating all: runs SQL first, then App Service, and **automatically sets `DefaultConnection`** on the App Service
- Prints a **post-setup summary** at the end with:
  - The ADO.NET connection string
  - TODO checklist (connection string, firewall, logging, publish profile)
  - The publish profile XML (ready to copy into GitHub secrets)

### App Service (`app-service/create.sh`)

- Creates App Service Plan + App Service
- Enables run-from-package mode
- Enables basic auth for publish profile download
- Enables application logging (if `APP_LOG_ENABLED=true` in `variables.sh`)

### SQL (`sql/create.sh`)

- Creates SQL Server (SQL + Entra auth)
- Configures firewall rules (Azure services + IP whitelist)
- Creates SQL Database
- Calls `grant-access.sh` to grant data-plane access to `$SQL_DB_PRINCIPALS`

### SQL grants (`sql/grant-access.sh`)

- Standalone, idempotent. Runnable any time without re-creating the DB.
- Reads `$SQL_DB_PRINCIPALS` from `variables.sh` (format: `"name:role1,role2"`)
- Issues `CREATE USER ... FROM EXTERNAL PROVIDER` + `ALTER ROLE ... ADD MEMBER`
- Auth: uses your `az login` session (no interactive password prompt) via
  `sqlcmd --authentication-method ActiveDirectoryDefault`, falling back to
  PowerShell + `Invoke-Sqlcmd -AccessToken` on Windows
- **Required for App Service / Function App MIs to talk to SQL** — without
  this, every request gets `Login failed for user '<token-identified principal>'`

### Storage (`storage/create.sh`)

- Creates a Standard_LRS storage account
- Reuses `$RESOURCE_GROUP` and `$APP_SERVICE_LOCATION` from `variables.sh`

### Function App (`function/create.sh`)

- Creates a Consumption-plan Function App (Windows, .NET isolated worker)
- Reuses `$RESOURCE_GROUP`, `$APP_SERVICE_LOCATION`, and `$STORAGE_ACCOUNT_NAME`
- Errors out if the storage account doesn't exist yet — run `storage/create.sh` first
- Teardown also cleans up the implicit Y1 consumption plan when it has no other apps

### Key Vault (`keyvault/create.sh`)

- Creates a Key Vault with RBAC authorization enabled (the modern default)
- Soft-delete is always on (Azure requirement since 2020); retention defaults to 90 days
- Idempotent: re-running detects an existing vault, **or recovers a soft-deleted one** with the same name
- Purge protection is **off** by default — enable it via `KEY_VAULT_ENABLE_PURGE_PROTECTION=true` for prod (irreversible)
- Optional self role assignment via `KEY_VAULT_SELF_ROLE` (e.g. `"Key Vault Secrets Officer"`)
- Teardown soft-deletes the vault; set `KEY_VAULT_PURGE_ON_TEARDOWN=true` in your shell to also purge it

## Post-setup (when running scripts individually)

When using `create.sh` with **ALL**, most of these are handled automatically. When running scripts individually, you'll need to do them manually:

### 1. Set the database connection string

```bash
az webapp config connection-string set \
    --name <APP_SERVICE_NAME> \
    --resource-group <RESOURCE_GROUP> \
    --connection-string-type SQLAzure \
    --settings DefaultConnection="<your-connection-string>"
```

The ADO.NET connection string is printed in the summary after SQL creation.

### 2. Whitelist your IP for database access

To connect to the SQL Database from your local machine (e.g. for running migrations or debugging), either:

- Add your IP to `SQL_FIREWALL_RULES` in `variables.sh` and re-run `sh infra/sql/create.sh`, or
- Add it manually in the Azure Portal: SQL Server > **Networking** > **Add your client IPv4 address**

### 3. Configure GitHub Actions deployment

Add the publish profile as a GitHub secret:

1. Copy the publish profile XML printed in the summary (or retrieve it from Azure Portal > App Service > **Download publish profile**)
2. In your GitHub repo, go to **Settings > Secrets and variables > Actions**
3. Create secret `AZURE_WEBAPP_PUBLISH_PROFILE` with the profile contents

## Notes

- The resource group is shared and is **never deleted** by these scripts.
- The App Service Plan uses the **F1 (Free)** tier by default. Change `SKU` in `variables.sh` to upgrade.
- `variables.sh` stays at the infra root so it can be shared across resource-type subfolders.
