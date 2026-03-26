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
├── variables.sh              # Shared configuration (resource names, SKU, region)
├── app-service/
│   ├── create.sh             # Creates App Service Plan + App Service (idempotent)
│   └── teardown.sh           # Deletes App Service + App Service Plan
├── sql/
│   ├── create.sh             # Creates SQL Server + SQL Database (idempotent)
│   └── teardown.sh           # Deletes SQL Database + SQL Server
└── README.md
```

## Usage

```bash
# Create App Service resources
sh infra/app-service/create.sh

# Create SQL resources (prompts for admin password if not set)
SQL_ADMIN_PASSWORD="YourPassword" sh infra/sql/create.sh

# Tear down App Service resources
sh infra/app-service/teardown.sh

# Tear down SQL resources
sh infra/sql/teardown.sh
```

## Post-setup

After creating the App Service, retrieve the publish profile for GitHub Actions deployment:

1. Go to [Azure Portal](https://portal.azure.com) > App Service > `HelloWorld-BelieveIt`
2. Click **Download publish profile**
3. In your GitHub repo, go to **Settings > Secrets and variables > Actions**
4. Create secret `AZURE_WEBAPP_PUBLISH_PROFILE` with the profile contents

## Notes

- The resource group is shared and is **never deleted** by these scripts.
- The App Service Plan uses the **F1 (Free)** tier by default. Change `SKU` in `variables.sh` to upgrade.
- `variables.sh` stays at the infra root so it can be shared across resource-type subfolders.
