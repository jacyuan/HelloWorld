#!/bin/bash
set -e

# =============================================================================
# Teardown Azure Key Vault
# Deletes the vault (which enters soft-deleted state). Optionally purges it
# if KEY_VAULT_PURGE_ON_TEARDOWN=true and purge protection is not enabled.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../variables.sh"

echo "=== Azure Key Vault Teardown ==="
echo "This will delete the following resource:"
echo "  - Key Vault:       $KEY_VAULT_NAME"
echo "  - Resource Group:  $RESOURCE_GROUP (NOT deleted — shared)"
echo ""
echo "Note: deletion is recoverable for $KEY_VAULT_RETENTION_DAYS days via 'az keyvault recover'."
echo "================================="
echo ""

if [ "$SKIP_CONFIRM" != "1" ]; then
    read -p "Are you sure? (y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo ""

# --- Delete the vault (soft-delete) ---
if "$AZ_CMD" keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "[..] Deleting key vault '$KEY_VAULT_NAME' (soft-delete)..."
    "$AZ_CMD" keyvault delete \
        --name "$KEY_VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP"
    echo "[OK] Key vault soft-deleted."
else
    echo "[--] Key vault '$KEY_VAULT_NAME' not found. Skipping delete."
fi

# --- Optional: purge the soft-deleted vault ---
# Set KEY_VAULT_PURGE_ON_TEARDOWN=true in your shell (NOT in variables.sh) to
# permanently delete and free the global name. Will fail if purge protection
# was enabled on the vault.
if [ "$KEY_VAULT_PURGE_ON_TEARDOWN" = "true" ]; then
    echo ""
    echo "[..] Purging soft-deleted vault '$KEY_VAULT_NAME' (irreversible)..."
    "$AZ_CMD" keyvault purge --name "$KEY_VAULT_NAME" --location "$KEY_VAULT_LOCATION"
    echo "[OK] Vault purged. Name '$KEY_VAULT_NAME' is now globally available again."
fi

echo ""
echo "=== Teardown complete ==="
