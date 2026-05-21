#!/bin/bash
set -e

# =============================================================================
# Grant data-plane access on the SQL Database to Entra principals.
# Reads $SQL_DB_PRINCIPALS from variables.sh.
#
# Idempotent: creates the user only if missing; ALTER ROLE ADD MEMBER is a
# no-op when the principal is already in the role.
#
# Authenticates to SQL using the caller's az CLI session (no interactive
# prompt). Requires:
#   - You are logged in via `az login` and have access to the DB.
#   - You are the SQL Entra admin (set in variables.sh as $SQL_ENTRA_ADMIN_EMAIL)
#     OR have been granted db_owner already.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../variables.sh"

echo "=== Grant SQL Database access ==="
echo "Server:    $SQL_SERVER_NAME"
echo "Database:  $SQL_DATABASE_NAME"
echo "Caller:    $("$AZ_CMD" account show --query user.name -o tsv 2>/dev/null || echo "unknown")"
echo "================================="
echo ""

if [ ${#SQL_DB_PRINCIPALS[@]} -eq 0 ]; then
    echo "[--] No principals configured in SQL_DB_PRINCIPALS. Nothing to do."
    exit 0
fi

# --- Generate SQL script (idempotent) ---
SQL_FILE="$SCRIPT_DIR/grant-access.generated.sql"
: > "$SQL_FILE"

for entry in "${SQL_DB_PRINCIPALS[@]}"; do
    IFS=':' read -r principal roles <<< "$entry"
    if [ -z "$principal" ] || [ -z "$roles" ]; then
        echo "[WARN] Skipping malformed entry: '$entry' (expected 'name:role1,role2')"
        continue
    fi
    echo "  + $principal -> $roles"

    cat >> "$SQL_FILE" <<EOF
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$principal')
BEGIN
    CREATE USER [$principal] FROM EXTERNAL PROVIDER;
    PRINT 'Created user [$principal]';
END
ELSE
    PRINT 'User [$principal] already exists';
GO
EOF

    IFS=',' read -ra role_array <<< "$roles"
    for role in "${role_array[@]}"; do
        role=$(echo "$role" | xargs)  # trim whitespace
        cat >> "$SQL_FILE" <<EOF
ALTER ROLE $role ADD MEMBER [$principal];
PRINT 'Added [$principal] to $role';
GO
EOF
    done
done

echo ""
echo "[OK] SQL script written: $SQL_FILE"
echo ""

# --- Execute via sqlcmd or PowerShell+Invoke-Sqlcmd ---
SQL_SERVER_FQDN="${SQL_SERVER_NAME}.database.windows.net"

execute_with_sqlcmd_modern() {
    # go-sqlcmd: uses az CLI session for AAD auth, no prompt
    sqlcmd -S "$SQL_SERVER_FQDN" -d "$SQL_DATABASE_NAME" \
        --authentication-method ActiveDirectoryDefault \
        -i "$SQL_FILE"
}

execute_with_powershell() {
    # Windows fallback: Invoke-Sqlcmd with az-issued access token
    local token
    token=$("$AZ_CMD" account get-access-token \
        --resource https://database.windows.net --query accessToken -o tsv)
    powershell.exe -NoProfile -Command "
        Invoke-Sqlcmd -ServerInstance '$SQL_SERVER_FQDN' \
            -Database '$SQL_DATABASE_NAME' \
            -AccessToken '$token' \
            -InputFile '$SQL_FILE' \
            -OutputSqlErrors \$true"
}

if command -v sqlcmd &>/dev/null; then
    echo "[..] Running grants via sqlcmd (ActiveDirectoryDefault)..."
    if execute_with_sqlcmd_modern; then
        echo "[OK] Grants applied."
        exit 0
    else
        echo "[WARN] sqlcmd failed (may be classic sqlcmd without --authentication-method). Trying PowerShell..."
    fi
fi

if command -v powershell.exe &>/dev/null; then
    echo "[..] Running grants via PowerShell + Invoke-Sqlcmd..."
    if execute_with_powershell; then
        echo "[OK] Grants applied."
        exit 0
    fi
fi

# --- Last resort: print instructions ---
echo ""
echo "[ERROR] Neither sqlcmd (modern) nor PowerShell+Invoke-Sqlcmd worked."
echo ""
echo "Run the generated SQL manually as the Entra admin:"
echo "  File: $SQL_FILE"
echo ""
echo "Options:"
echo "  - Portal:    SQL Database > Query editor (login as Entra admin) > paste & run"
echo "  - sqlcmd:    sqlcmd -S $SQL_SERVER_FQDN -d $SQL_DATABASE_NAME -G -i \"$SQL_FILE\""
echo ""
exit 1
