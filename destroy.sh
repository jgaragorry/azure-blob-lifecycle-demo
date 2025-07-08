#!/usr/bin/env bash
set -euo pipefail

export PYTHONWARNINGS="ignore::UserWarning"
export AZURE_CORE_ONLY_SHOW_ERRORS="1"
az() { command az "$@" 2> >(grep -v "pkg_resources is deprecated" >&2); }

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-blob-demo}"

echo -e "\n🗑️  Eliminando RG $RESOURCE_GROUP …"
az group delete --name "$RESOURCE_GROUP" --yes --no-wait
echo "⏳ Esperando a que Azure confirme…"
az group wait --name "$RESOURCE_GROUP" --deleted
echo "✅ Todos los recursos se han eliminado."