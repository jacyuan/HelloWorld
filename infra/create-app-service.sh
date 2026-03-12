#!/bin/bash
set -e

# =============================================================================
# Create Azure App Service Plan + App Service (idempotent)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/variables.sh"

echo "=== Azure App Service Setup ==="
echo "Resource Group:    $RESOURCE_GROUP"
echo "Location:          $LOCATION"
echo "App Service Plan:  $APP_SERVICE_PLAN (SKU: $SKU)"
echo "App Service:       $APP_SERVICE_NAME"
echo "Runtime:           $RUNTIME"
echo "==============================="
echo ""

# --- App Service Plan ---
if "$AZ_CMD" appservice plan show --name "$APP_SERVICE_PLAN" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "[OK] App Service Plan '$APP_SERVICE_PLAN' already exists. Skipping."
else
    echo "[..] Creating App Service Plan '$APP_SERVICE_PLAN'..."
    "$AZ_CMD" appservice plan create \
        --name "$APP_SERVICE_PLAN" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku "$SKU" \
        --is-linux
    echo "[OK] App Service Plan created."
fi

echo ""

# --- App Service ---
if "$AZ_CMD" webapp show --name "$APP_SERVICE_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "[OK] App Service '$APP_SERVICE_NAME' already exists. Skipping."
else
    echo "[..] Creating App Service '$APP_SERVICE_NAME'..."
    "$AZ_CMD" webapp create \
        --name "$APP_SERVICE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --plan "$APP_SERVICE_PLAN" \
        --runtime "$RUNTIME"
    echo "[OK] App Service created."
fi

# --- Enable basic auth (required for publish profile download) ---
echo "[..] Enabling basic authentication for publish profile..."
"$AZ_CMD" resource update \
    --resource-group "$RESOURCE_GROUP" \
    --name scm \
    --namespace Microsoft.Web \
    --resource-type basicPublishingCredentialsPolicies \
    --parent "sites/$APP_SERVICE_NAME" \
    --set properties.allow=true &>/dev/null
"$AZ_CMD" resource update \
    --resource-group "$RESOURCE_GROUP" \
    --name ftp \
    --namespace Microsoft.Web \
    --resource-type basicPublishingCredentialsPolicies \
    --parent "sites/$APP_SERVICE_NAME" \
    --set properties.allow=true &>/dev/null
echo "[OK] Basic authentication enabled."

echo ""
echo "=== Done ==="
