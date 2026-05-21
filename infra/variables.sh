#!/bin/bash

# =============================================================================
# Azure CLI command (use "az.cmd" on Windows/MSYS, "az" on Linux/macOS)
# =============================================================================
AZ_CMD="C:\Tools\azure-cli\bin\az.cmd"

# =============================================================================
# Azure resource configuration
# =============================================================================

# Shared resource group
RESOURCE_GROUP="RG-Student-04"

# Regions
APP_SERVICE_LOCATION="westeurope"

# App Service Plan
APP_SERVICE_PLAN="HelloWorld-Yuan-AppServicePlan"
SKU="F1"

# App Service
APP_SERVICE_NAME="HelloWorld-Yuan-AppService"
RUNTIME="DOTNETCORE:10.0"
# Activate application logging and set log level (optional)
APP_LOG_ENABLED="true"
APP_LOG_LEVEL="information"  # verbose, information, warning, error

# SQL Server
SQL_SERVER_NAME="HelloWorld-Yuan-SqlServer"  # Must be globally unique
SQL_LOCATION="francecentral"
SQL_ADMIN_USER="dbserveradmin"
SQL_ADMIN_PASSWORD="AdminDb_04_PacceM0rd"  # Set via environment variable or pass as argument
SQL_ENTRA_ADMIN_EMAIL="yuan.lin@believeit.fr"  # Set to the Entra user/group email to be SQL admin

# SQL Database
SQL_DATABASE_NAME="HelloWorld-Yuan-Db"
SQL_SKU="Basic"
SQL_USE_ELASTIC_POOL="false"
SQL_ELASTIC_POOL_NAME=""
SQL_WORKLOAD_ENV="Development"
SQL_BACKUP_REDUNDANCY="Local"

# SQL Firewall — IP whitelist for remote access
# Format: "RuleName:StartIP:EndIP" (one entry per line)
# For a single IP, use the same value for start and end.
# Examples:
#   "Office:203.0.113.10:203.0.113.10"       — single IP
#   "VPN-Range:10.0.0.1:10.0.0.255"          — IP range
SQL_FIREWALL_RULES=(
    # "MyIP:x.x.x.x:x.x.x.x"
    "HOME:176.142.246.79:176.142.246.79"
)

# =============================================================================
# Storage Account
# =============================================================================
# Reuses $RESOURCE_GROUP and $APP_SERVICE_LOCATION.
# To pair the storage account with SQL instead, change the --location reference
# in storage/create.sh to "$SQL_LOCATION".
STORAGE_ACCOUNT_NAME="azurequizlab04"   # 3-24 chars, lowercase letters + digits, globally unique
STORAGE_ACCOUNT_SKU="Standard_LRS"      # Standard performance, locally redundant storage

# =============================================================================
# Key Vault
# =============================================================================
# Reuses $RESOURCE_GROUP. Vault names are globally unique within the soft-delete
# retention window (i.e. a deleted vault still reserves its name for 7-90 days).
KEY_VAULT_NAME="helloworld-yuan"                # 3-24 chars, alphanumeric + hyphens, globally unique
KEY_VAULT_LOCATION="francecentral"              # Independent location (paired with SQL by default)
KEY_VAULT_SKU="standard"                        # standard | premium
KEY_VAULT_ENABLE_RBAC="true"                    # RBAC authorization (recommended over access policies)
KEY_VAULT_ENABLE_PURGE_PROTECTION="false"       # IRREVERSIBLE once true — blocks early purge
KEY_VAULT_RETENTION_DAYS="90"                   # 7-90, soft-delete retention period
KEY_VAULT_PUBLIC_NETWORK_ACCESS="Enabled"       # Enabled | Disabled (use private endpoint if Disabled)

# Optional: RBAC role to grant the current signed-in principal on create.
# Without a role, you cannot read/write secrets even if you created the vault.
# Common roles: "Key Vault Administrator", "Key Vault Secrets Officer",
#               "Key Vault Crypto Officer", "Key Vault Certificates Officer".
# Leave empty ("") to skip role assignment.
KEY_VAULT_SELF_ROLE=""

# =============================================================================
# Function App
# =============================================================================
# Reuses $RESOURCE_GROUP, $APP_SERVICE_LOCATION, and $STORAGE_ACCOUNT_NAME.
# The create script currently only handles "consumption". To support flex/premium/
# appservice, extend function/create.sh with a case branch on FUNCTION_APP_PLAN_TYPE.
FUNCTION_APP_NAME="azurequizlab-functions-04"   # 2-60 chars, globally unique
FUNCTION_APP_PLAN_TYPE="consumption"            # consumption | flex | premium | appservice
FUNCTION_APP_OS="windows"                       # windows | linux
FUNCTION_APP_RUNTIME="dotnet-isolated"          # required for .NET 5+ (in-process is being retired)
FUNCTION_APP_RUNTIME_VERSION="9"              # .NET runtime version
FUNCTIONS_VERSION="4"                           # Azure Functions runtime (host) version
