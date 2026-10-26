#!/usr/bin/env bash
# Ручное создание ВМ в приватной подсети для последующего terraform import.
# Параметры ВМ совпадают с ресурсом yandex_compute_instance.imported.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${YC_ENV_FILE:-$HOME/.config/yandex-cloud/codeby-terraform.env}"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

YC_BIN="${YC_BIN:-$HOME/.local/yandex-cloud/bin/yc}"
TERRAFORM="${TERRAFORM:-$HOME/.local/bin/terraform}"
TF_DIR="$ROOT/terraform/private"
INSTANCE_NAME="${INSTANCE_NAME:-codeby-lesson14-manual}"
ZONE="${YC_ZONE:-ru-central1-a}"
IMAGE_FAMILY="${IMAGE_FAMILY:-ubuntu-2204-lts}"
VM_USER="${VM_USER:-ubuntu}"
SSH_PUB_KEY="${SSH_PUB_KEY:-$HOME/.ssh/codeby_lesson14.pub}"

if [[ ! -x "$YC_BIN" ]]; then
  echo "Не найден yc: $YC_BIN" >&2
  exit 1
fi
if [[ ! -f "$SSH_PUB_KEY" ]]; then
  echo "Не найден публичный SSH-ключ: $SSH_PUB_KEY" >&2
  exit 1
fi

cd "$TF_DIR"
SUBNET_ID="$("$TERRAFORM" output -raw private_subnet_id)"
SG_ID="$("$TERRAFORM" output -raw private_security_group_id)"

echo "Создаю ВМ $INSTANCE_NAME в приватной подсети $SUBNET_ID..."
INSTANCE_JSON="$(
  "$YC_BIN" compute instance create \
    --name "$INSTANCE_NAME" \
    --description "Manually created VM imported into Terraform" \
    --zone "$ZONE" \
    --platform standard-v3 \
    --cores 2 \
    --memory 2G \
    --core-fraction 20 \
    --create-boot-disk "image-family=$IMAGE_FAMILY,size=10" \
    --network-interface "subnet-id=$SUBNET_ID,nat=false,security-group-ids=$SG_ID" \
    --metadata "ssh-keys=$VM_USER:$(cat "$SSH_PUB_KEY")" \
    --format json
)"

mkdir -p "$ROOT/logs"
printf '%s\n' "$INSTANCE_JSON" >"$ROOT/logs/manual-instance-create.json"
INSTANCE_ID="$(jq -r '.id' <<<"$INSTANCE_JSON")"
printf '%s\n' "$INSTANCE_ID" >"$ROOT/logs/manual-instance-id.txt"

echo "ВМ создана вручную: $INSTANCE_ID"
echo "ID сохранён в logs/manual-instance-id.txt"
echo
echo "Импорт:"
echo "  ./scripts/import-manual-vm.sh"
