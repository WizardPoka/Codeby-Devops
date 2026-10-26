#!/usr/bin/env bash
# Импорт вручную созданной ВМ во вторую конфигурацию Terraform.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${YC_ENV_FILE:-$HOME/.config/yandex-cloud/codeby-terraform.env}"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

TERRAFORM="${TERRAFORM:-$HOME/.local/bin/terraform}"
TF_DIR="$ROOT/terraform/private"
INSTANCE_ID="${1:-$(cat "$ROOT/logs/manual-instance-id.txt" 2>/dev/null || true)}"

if [[ -z "$INSTANCE_ID" ]]; then
  echo "Укажите ID ВМ: ./scripts/import-manual-vm.sh <instance-id>" >&2
  exit 1
fi

cd "$TF_DIR"

if "$TERRAFORM" state list 2>/dev/null | grep -qx 'yandex_compute_instance.imported\[0\]'; then
  echo "Ресурс уже импортирован."
  exit 0
fi

mkdir -p "$ROOT/logs"
{
  echo "### terraform import"
  "$TERRAFORM" import \
    -var manage_imported_vm=true \
    'yandex_compute_instance.imported[0]' "$INSTANCE_ID"
  echo
  echo "### terraform plan after import"
  "$TERRAFORM" plan -input=false -var manage_imported_vm=true
} 2>&1 | tee "$ROOT/logs/terraform-import.txt"
