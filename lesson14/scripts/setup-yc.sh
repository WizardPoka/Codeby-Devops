#!/usr/bin/env bash
# Подготовка Yandex Cloud к уроку 14:
#   - yc init, если профиля ещё нет;
#   - SSH-ключ для ВМ;
#   - service account с ролью editor и IAM-ключом;
#   - env-файл для Terraform;
#   - terraform.tfvars для обеих конфигураций.
#
# Скрипт не печатает секреты. IAM-ключ остаётся в ~/.config/yandex-cloud.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

find_yc() {
  if [[ -n "${YC_BIN:-}" ]]; then
    printf '%s\n' "$YC_BIN"
  elif command -v yc >/dev/null 2>&1; then
    command -v yc
  elif [[ -x "$HOME/.local/yandex-cloud/bin/yc" ]]; then
    printf '%s\n' "$HOME/.local/yandex-cloud/bin/yc"
  else
    echo "Не найден yc. Установите Yandex Cloud CLI." >&2
    exit 1
  fi
}

YC_BIN="$(find_yc)"

if ! "$YC_BIN" config get folder-id >/dev/null 2>&1; then
  echo "Профиль yc не настроен. Запускаю yc init."
  echo "Выберите облако, каталог и зону ru-central1-a."
  "$YC_BIN" init
fi

CLOUD_ID="$("$YC_BIN" config get cloud-id)"
FOLDER_ID="$("$YC_BIN" config get folder-id)"
ZONE="${YC_ZONE:-$("$YC_BIN" config get compute-default-zone 2>/dev/null || true)}"
ZONE="${ZONE:-ru-central1-a}"

SSH_KEY="${SSH_KEY:-$HOME/.ssh/codeby_lesson14}"
if [[ ! -f "$SSH_KEY" ]]; then
  mkdir -p "$(dirname "$SSH_KEY")"
  ssh-keygen -t ed25519 -N "" -C "codeby-lesson14" -f "$SSH_KEY"
fi
chmod 600 "$SSH_KEY"
chmod 644 "$SSH_KEY.pub"

SA_NAME="${SA_NAME:-codeby-terraform}"
SA_ID="$(
  "$YC_BIN" iam service-account get --name "$SA_NAME" --format json 2>/dev/null \
    | jq -r '.id // empty' || true
)"

if [[ -z "$SA_ID" ]]; then
  echo "Создаю service account $SA_NAME..."
  SA_ID="$(
    "$YC_BIN" iam service-account create \
      --name "$SA_NAME" \
      --description "Terraform for Codeby lesson 14" \
      --format json \
      | jq -r '.id'
  )"
fi

BINDINGS="$("$YC_BIN" resource-manager folder list-access-bindings "$FOLDER_ID" --format json)"
if ! jq -e --arg id "$SA_ID" \
  '.[] | select(.roleId == "editor" and .subject.id == $id)' \
  <<<"$BINDINGS" >/dev/null; then
  echo "Выдаю service account роль editor на каталог..."
  "$YC_BIN" resource-manager folder add-access-binding "$FOLDER_ID" \
    --role editor \
    --subject "serviceAccount:$SA_ID"
fi

YC_CONFIG_DIR="${YC_CONFIG_DIR:-$HOME/.config/yandex-cloud}"
mkdir -p "$YC_CONFIG_DIR"
chmod 700 "$YC_CONFIG_DIR"

KEY_FILE="$YC_CONFIG_DIR/codeby-terraform-key.json"
if [[ ! -f "$KEY_FILE" ]]; then
  echo "Создаю IAM-ключ service account..."
  "$YC_BIN" iam key create \
    --service-account-id "$SA_ID" \
    --output "$KEY_FILE"
  chmod 600 "$KEY_FILE"
fi

ENV_FILE="$YC_CONFIG_DIR/codeby-terraform.env"
cat >"$ENV_FILE" <<EOF
export YC_SERVICE_ACCOUNT_KEY_FILE="$KEY_FILE"
export YC_CLOUD_ID="$CLOUD_ID"
export YC_FOLDER_ID="$FOLDER_ID"
export YC_ZONE="$ZONE"
export TF_CLI_CONFIG_FILE="$ROOT/terraform/terraform.rc"
EOF
chmod 600 "$ENV_FILE"

for dir in public private; do
  cat >"$ROOT/terraform/$dir/terraform.tfvars" <<EOF
cloud_id  = "$CLOUD_ID"
folder_id = "$FOLDER_ID"
zone      = "$ZONE"

ssh_public_key_path  = "$SSH_KEY.pub"
ssh_private_key_path = "$SSH_KEY"
EOF
done

# Для приватной конфигурации добавляем выключенный импорт.
cat >>"$ROOT/terraform/private/terraform.tfvars" <<'EOF'

manage_imported_vm = false
EOF

echo
echo "Готово."
echo "  cloud_id  = $CLOUD_ID"
echo "  folder_id = $FOLDER_ID"
echo "  zone      = $ZONE"
echo "  ssh key   = $SSH_KEY"
echo
echo "Перед работой с Terraform выполните:"
echo "  source \"$ENV_FILE\""
echo
echo "Дальше:"
echo "  cd \"$ROOT/terraform/public\"  && terraform init && terraform apply"
echo "  cd \"$ROOT/terraform/private\" && terraform init && terraform apply"
