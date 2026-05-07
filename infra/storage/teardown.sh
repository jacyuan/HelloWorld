#!/bin/bash
set -e

# =============================================================================
# Teardown Azure Storage Account
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../variables.sh"

echo "=== Azure Storage Account Teardown ==="
echo "This will delete the following resources:"
echo "  - Storage Account: $STORAGE_ACCOUNT_NAME"
echo "  - Resource Group:  $RESOURCE_GROUP (NOT deleted — shared)"
echo "======================================="
echo ""

if [ "$SKIP_CONFIRM" != "1" ]; then
    read -p "Are you sure? (y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo ""

# --- Storage Account ---
if "$AZ_CMD" storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "[..] Deleting storage account '$STORAGE_ACCOUNT_NAME'..."
    "$AZ_CMD" storage account delete \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --yes
    echo "[OK] Storage account deleted."
else
    echo "[--] Storage account '$STORAGE_ACCOUNT_NAME' not found. Skipping."
fi

echo ""
echo "=== Teardown complete ==="
