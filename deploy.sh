#!/usr/bin/env bash
set -euo pipefail

# === Cabecera común ===
export PYTHONWARNINGS="ignore::UserWarning"
export AZURE_CORE_ONLY_SHOW_ERRORS="1"
az() { command az "$@" 2> >(grep -v "pkg_resources is deprecated" >&2); }
log(){ echo "$(date +%H:%M:%S) - $*"; }

# --- Parámetros -----------------------------
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-blob-demo}"
LOCATION="${LOCATION:-eastus}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-stor$(openssl rand -hex 4)}"
TAGS="owner=$(whoami) purpose=blob-lifecycle-demo cost-center=training environment=demo"

# --- Creación RG & SA -----------------------
log "Creando Resource Group '$RESOURCE_GROUP' en '$LOCATION'…"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --tags "$TAGS" >/dev/null

log "Creando Storage Account '$STORAGE_ACCOUNT'…"
az storage account create \
  --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --location "$LOCATION" \
  --sku Standard_LRS --kind StorageV2 --https-only true --min-tls-version TLS1_2 \
  --allow-blob-public-access false --public-network-access Enabled --tags "$TAGS" >/dev/null

# --- Contenedores ---------------------------
log "Creando contenedores (hot, cool, archive)…"
for c in hot cool archive; do
  az storage container create --name "$c" --account-name "$STORAGE_ACCOUNT" --auth-mode login --public-access off >/dev/null
done

# --- Política de ciclo de vida --------------
log "Aplicando política de ciclo de vida…"
cat > lifecycle.json <<'EOF'
{
  "rules": [
    { "enabled": true, "name": "AutoCool", "type": "Lifecycle",
      "definition": { "filters": {"blobTypes":["blockBlob"],"prefixMatch":["cool/"]},
        "actions": {"baseBlob": {"tierToCool": {"daysAfterModificationGreaterThan": 0}}}} },
    { "enabled": true, "name": "AutoArchive", "type": "Lifecycle",
      "definition": { "filters": {"blobTypes":["blockBlob"],"prefixMatch":["archive/"]},
        "actions": {"baseBlob": {"tierToArchive": {"daysAfterModificationGreaterThan": 0}}}} }
  ]
}
EOF
az storage account management-policy create --account-name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --policy @lifecycle.json >/dev/null
rm lifecycle.json

echo "$STORAGE_ACCOUNT" > .last_sa
log "✅ Despliegue completado – Storage Account: $STORAGE_ACCOUNT"