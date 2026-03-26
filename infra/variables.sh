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

# Region
LOCATION="westeurope"

# App Service Plan
APP_SERVICE_PLAN="HelloWorld-BelieveIt-Plan"
SKU="F1"

# App Service
APP_SERVICE_NAME="HelloWorld-Yuan"
RUNTIME="DOTNETCORE:10.0"

# SQL Server
SQL_SERVER_NAME="helloworld-yuan-sqlserver"  # Must be globally unique
LOCATION_SQL="francecentral"
SQL_ADMIN_USER="dbserveradmin"
SQL_ADMIN_PASSWORD="Admin01_HelloWorldYuan"  # Set via environment variable or pass as argument
SQL_ENTRA_ADMIN_EMAIL="yuan.lin@believeit.fr"  # Set to the Entra user/group email to be SQL admin

# SQL Database
SQL_DATABASE_NAME="HelloWorldYuanDb"
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
    "Home:176.142.246.79:176.142.246.79"
)
