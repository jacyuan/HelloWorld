#!/bin/bash
set -e

# =============================================================================
# Create Azure Storage Account (idempotent)
# Reuses $RESOURCE_GROUP and $APP_SERVICE_LOCATION from variables.sh.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../variables.sh"

echo "=== Azure Storage Account Setup ==="
echo "Resource Group:    $RESOURCE_GROUP"
echo "Location:          $APP_SERVICE_LOCATION"
echo "Storage Account:   $STORAGE_ACCOUNT_NAME"
echo "SKU:               $STORAGE_ACCOUNT_SKU"
echo "===================================="
echo ""

# --- Storage Account ---
if "$AZ_CMD" storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "[OK] Storage account '$STORAGE_ACCOUNT_NAME' already exists. Skipping."
else
    echo "[..] Creating storage account '$STORAGE_ACCOUNT_NAME'..."
    "$AZ_CMD" storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$APP_SERVICE_LOCATION" \
        --sku "$STORAGE_ACCOUNT_SKU"
    echo "[OK] Storage account created."
fi

echo ""
echo "=== Done ==="
