#!/bin/bash
set -e

# =============================================================================
# Teardown Azure Function App
# Also deletes the implicit Y1 (consumption) plan if it has no other apps.
# Storage account is NOT deleted here — use storage/teardown.sh for that.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../variables.sh"

echo "=== Azure Function App Teardown ==="
echo "This will delete the following resources:"
echo "  - Function App:     $FUNCTION_APP_NAME"
echo "  - Consumption Plan: (auto-detected, deleted only if orphaned)"
echo "  - Resource Group:   $RESOURCE_GROUP (NOT deleted — shared)"
echo "  - Storage Account:  $STORAGE_ACCOUNT_NAME (NOT deleted — separate teardown)"
echo "===================================="
echo ""

if [ "$SKIP_CONFIRM" != "1" ]; then
    read -p "Are you sure? (y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo ""

# --- Function App ---
if "$AZ_CMD" functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    # Capture the plan id BEFORE deleting the function app — afterwards it's gone.
    PLAN_ID=$("$AZ_CMD" functionapp show \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "appServicePlanId" -o tsv)

    echo "[..] Deleting Function App '$FUNCTION_APP_NAME'..."
    "$AZ_CMD" functionapp delete \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$RESOURCE_GROUP"
    echo "[OK] Function App deleted."

    # --- Orphaned consumption plan cleanup ---
    if [ -n "$PLAN_ID" ]; then
        PLAN_NAME=$(basename "$PLAN_ID")
        PLAN_RG=$(echo "$PLAN_ID" | awk -F/ '{print $5}')
        APP_COUNT=$("$AZ_CMD" appservice plan show \
            --name "$PLAN_NAME" \
            --resource-group "$PLAN_RG" \
            --query "numberOfSites" -o tsv 2>/dev/null || echo "0")
        if [ "$APP_COUNT" = "0" ]; then
            echo "[..] Deleting orphaned consumption plan '$PLAN_NAME'..."
            "$AZ_CMD" appservice plan delete \
                --name "$PLAN_NAME" \
                --resource-group "$PLAN_RG" \
                --yes &>/dev/null
            echo "[OK] Plan deleted."
        else
            echo "[--] Plan '$PLAN_NAME' still hosts $APP_COUNT other app(s). Skipping."
        fi
    fi
else
    echo "[--] Function App '$FUNCTION_APP_NAME' not found. Skipping."
fi

echo ""
echo "=== Teardown complete ==="
