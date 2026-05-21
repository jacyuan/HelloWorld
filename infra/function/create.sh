#!/bin/bash
set -e

# =============================================================================
# Create Azure Function App (idempotent)
# Reuses $RESOURCE_GROUP, $APP_SERVICE_LOCATION, and $STORAGE_ACCOUNT_NAME.
# Currently supports only FUNCTION_APP_PLAN_TYPE=consumption.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../variables.sh"

# --- Validate plan type (only consumption is supported by this script today) ---
if [ "$FUNCTION_APP_PLAN_TYPE" != "consumption" ]; then
    echo "[ERROR] FUNCTION_APP_PLAN_TYPE='$FUNCTION_APP_PLAN_TYPE' is not yet supported."
    echo "        Currently supported: consumption"
    exit 1
fi

echo "=== Azure Function App Setup ==="
echo "Resource Group:    $RESOURCE_GROUP"
echo "Location:          $APP_SERVICE_LOCATION"
echo "Function App:      $FUNCTION_APP_NAME"
echo "Plan Type:         $FUNCTION_APP_PLAN_TYPE"
echo "OS:                $FUNCTION_APP_OS"
echo "Runtime:           $FUNCTION_APP_RUNTIME $FUNCTION_APP_RUNTIME_VERSION"
echo "Functions ver.:    $FUNCTIONS_VERSION"
echo "Storage Account:   $STORAGE_ACCOUNT_NAME"
echo "================================="
echo ""

# --- Storage account dependency check ---
if ! "$AZ_CMD" storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "[ERROR] Storage account '$STORAGE_ACCOUNT_NAME' not found."
    echo "        Run 'sh infra/storage/create.sh' first (or 'sh infra/create.sh' and choose ALL)."
    exit 1
fi

# --- Function App ---
if "$AZ_CMD" functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "[OK] Function App '$FUNCTION_APP_NAME' already exists. Skipping."
else
    echo "[..] Creating Function App '$FUNCTION_APP_NAME' (Consumption, $FUNCTION_APP_OS)..."
    "$AZ_CMD" functionapp create \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --consumption-plan-location "$APP_SERVICE_LOCATION" \
        --os-type "$FUNCTION_APP_OS" \
        --runtime "$FUNCTION_APP_RUNTIME" \
        --runtime-version "$FUNCTION_APP_RUNTIME_VERSION" \
        --functions-version "$FUNCTIONS_VERSION" \
        --storage-account "$STORAGE_ACCOUNT_NAME"
    echo "[OK] Function App created."
fi

echo ""
echo "=== Done ==="
