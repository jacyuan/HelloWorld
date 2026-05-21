#!/bin/bash
set -e

# =============================================================================
# Create Azure Key Vault (idempotent)
# Reuses $RESOURCE_GROUP from variables.sh. Location is configured separately
# via $KEY_VAULT_LOCATION because Key Vault names are globally unique.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../variables.sh"

echo "=== Azure Key Vault Setup ==="
echo "Resource Group:    $RESOURCE_GROUP"
echo "Location:          $KEY_VAULT_LOCATION"
echo "Key Vault:         $KEY_VAULT_NAME"
echo "SKU:               $KEY_VAULT_SKU"
echo "RBAC enabled:      $KEY_VAULT_ENABLE_RBAC"
echo "Purge protection:  $KEY_VAULT_ENABLE_PURGE_PROTECTION"
echo "Retention (days):  $KEY_VAULT_RETENTION_DAYS"
echo "Public access:     $KEY_VAULT_PUBLIC_NETWORK_ACCESS"
echo "============================="
echo ""

# --- Check for soft-deleted vault with the same name (would block create) ---
DELETED_VAULT=$("$AZ_CMD" keyvault list-deleted \
    --resource-type vault \
    --query "[?name=='$KEY_VAULT_NAME'].name" -o tsv 2>/dev/null || true)

if [ -n "$DELETED_VAULT" ]; then
    echo "[!!] A soft-deleted vault named '$KEY_VAULT_NAME' exists."
    echo "     Recovering it instead of creating a new one..."
    "$AZ_CMD" keyvault recover --name "$KEY_VAULT_NAME"
    echo "[OK] Vault recovered from soft-delete."
elif "$AZ_CMD" keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "[OK] Key Vault '$KEY_VAULT_NAME' already exists. Skipping create."
else
    echo "[..] Creating Key Vault '$KEY_VAULT_NAME'..."

    CREATE_ARGS=(
        --name "$KEY_VAULT_NAME"
        --resource-group "$RESOURCE_GROUP"
        --location "$KEY_VAULT_LOCATION"
        --sku "$KEY_VAULT_SKU"
        --enable-rbac-authorization "$KEY_VAULT_ENABLE_RBAC"
        --retention-days "$KEY_VAULT_RETENTION_DAYS"
        --public-network-access "$KEY_VAULT_PUBLIC_NETWORK_ACCESS"
    )

    # Purge protection is irreversible — only pass when explicitly enabled
    if [ "$KEY_VAULT_ENABLE_PURGE_PROTECTION" = "true" ]; then
        CREATE_ARGS+=(--enable-purge-protection true)
    fi

    "$AZ_CMD" keyvault create "${CREATE_ARGS[@]}"
    echo "[OK] Key Vault created."
fi

# --- Optional: assign RBAC role to the current signed-in principal ---
if [ -n "$KEY_VAULT_SELF_ROLE" ]; then
    echo ""
    echo "[..] Assigning role '$KEY_VAULT_SELF_ROLE' to current user on '$KEY_VAULT_NAME'..."

    PRINCIPAL_ID=$("$AZ_CMD" ad signed-in-user show --query id -o tsv)
    SUBSCRIPTION_ID=$("$AZ_CMD" account show --query id -o tsv)
    SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEY_VAULT_NAME"

    # TODO (learning hook): replace the block below with your role-assignment
    # logic. Considerations:
    #   - Should the assignment be idempotent? (re-running mustn't error if the
    #     role is already assigned — check with `az role assignment list`)
    #   - Do you want to silently skip on conflict, or surface a warning?
    #   - Should you assign to the signed-in user, a group, or a service
    #     principal? (groups are usually the right answer for teams)
    # 5-10 lines max.
    echo "[TODO] Role assignment not yet implemented — see TODO in keyvault/create.sh"
fi

echo ""
echo "Vault URI: https://${KEY_VAULT_NAME}.vault.azure.net/"
echo "=== Done ==="
