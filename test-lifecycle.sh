#!/usr/bin/env bash
set -euo pipefail

# === Cabecera común ===
export PYTHONWARNINGS="ignore::UserWarning"
export AZURE_CORE_ONLY_SHOW_ERRORS="1"
az() { command az "$@" 2> >(grep -v "pkg_resources is deprecated" >&2); }
log(){ echo "$(date +%H:%M:%S) - $*"; }

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-blob-demo}"
if [[ -f .last_sa ]]; then
  STORAGE_ACCOUNT="$(cat .last_sa)"
else
  STORAGE_ACCOUNT="$(az storage account list --resource-group "$RESOURCE_GROUP" --query "[?tags.purpose=='blob-lifecycle-demo'].name | [0]" -o tsv)"
fi
[[ -z "$STORAGE_ACCOUNT" ]] && { echo "Storage account no encontrado"; exit 1; }
ACCOUNT_KEY="$(az storage account keys list --account-name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --query "[0].value" -o tsv)"

# --- Carga de blobs -------------------------
log "Usando Storage Account '$STORAGE_ACCOUNT'"
log "Subiendo blobs de ejemplo…"
echo "Hello Azure Blob Storage $(date)" > sample.txt
for tier in hot cool archive; do
  az storage blob upload --account-name "$STORAGE_ACCOUNT" --account-key "$ACCOUNT_KEY" \
    --container-name "$tier" --file sample.txt --name "${tier}/sample-${tier}.txt" --no-progress >/dev/null
done
sleep 5

# --- Mostrar tier inicial ------------------
log "Tiers iniciales:"
for t in hot cool archive; do
  az storage blob show --account-name "$STORAGE_ACCOUNT" --account-key "$ACCOUNT_KEY" \
    --container-name "$t" --name "${t}/sample-${t}.txt" --query "[name, properties.blobTier]" -o tsv
done

# --- Transiciones ---------------------------
log "Transicionando Cool y Archive…"
az storage blob set-tier --account-name "$STORAGE_ACCOUNT" --account-key "$ACCOUNT_KEY" \
  --container-name cool --name "cool/sample-cool.txt" --tier Cool >/dev/null
az storage blob set-tier --account-name "$STORAGE_ACCOUNT" --account-key "$ACCOUNT_KEY" \
  --container-name archive --name "archive/sample-archive.txt" --tier Archive >/dev/null

log "Tiers después de la transición:"
for t in hot cool archive; do
  az storage blob show --account-name "$STORAGE_ACCOUNT" --account-key "$ACCOUNT_KEY" \
    --container-name "$t" --name "${t}/sample-${t}.txt" --query "[name, properties.blobTier]" -o tsv
done

# --- Descargas ------------------------------
log "Descargando desde Cool (ok)…"
az storage blob download --account-name "$STORAGE_ACCOUNT" --account-key "$ACCOUNT_KEY" \
  --container-name cool --name "cool/sample-cool.txt" --file sample-cool-downloaded.txt --no-progress >/dev/null
cat sample-cool-downloaded.txt

log "Intentando descargar desde Archive (fallará)…"
az storage blob download --account-name "$STORAGE_ACCOUNT" --account-key "$ACCOUNT_KEY" \
  --container-name archive --name "archive/sample-archive.txt" --file sample-archive-downloaded.txt --no-progress 2>/dev/null || \
  log "⚠️  Blob en Archive requiere rehidratación"

log "✅ Prueba de ciclo de vida finalizada"