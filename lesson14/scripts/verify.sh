#!/usr/bin/env bash
# Проверка после terraform apply: сохраняет выводы Terraform и ответы nginx.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${YC_ENV_FILE:-$HOME/.config/yandex-cloud/codeby-terraform.env}"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

TERRAFORM="${TERRAFORM:-$HOME/.local/bin/terraform}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/codeby_lesson14}"
mkdir -p "$ROOT/logs"

cd "$ROOT/terraform/public"
"$TERRAFORM" output -json >"$ROOT/logs/public-outputs.json"
PUBLIC_IP="$("$TERRAFORM" output -raw public_ip)"
PUBLIC_SUBNET_ID="$("$TERRAFORM" output -raw public_subnet_id)"

cd "$ROOT/terraform/private"
"$TERRAFORM" output -json >"$ROOT/logs/private-outputs.json"
PRIVATE_IP="$("$TERRAFORM" output -raw private_ip)"
PRIVATE_SUBNET_ID="$("$TERRAFORM" output -raw private_subnet_id)"

{
  echo "### public"
  echo "public_ip=$PUBLIC_IP"
  echo "public_subnet_id=$PUBLIC_SUBNET_ID"
  echo
  echo "### private"
  echo "private_ip=$PRIVATE_IP"
  echo "private_subnet_id=$PRIVATE_SUBNET_ID"
} >"$ROOT/logs/addresses.txt"

echo "### curl public nginx" | tee "$ROOT/logs/nginx-checks.txt"
curl -fsS -I "http://$PUBLIC_IP/" | tee -a "$ROOT/logs/nginx-checks.txt"

{
  echo
  echo "### private nginx from public VM"
  ssh -i "$SSH_KEY" \
    -o StrictHostKeyChecking=accept-new \
    -o UserKnownHostsFile="$HOME/.ssh/known_hosts" \
    "ubuntu@$PUBLIC_IP" \
    "curl -fsS -I http://$PRIVATE_IP:8080/ && echo && systemctl is-active nginx"
} 2>&1 | tee -a "$ROOT/logs/nginx-checks.txt"

{
  echo
  echo "### terraform state: public"
  (cd "$ROOT/terraform/public" && "$TERRAFORM" state list)
  echo
  echo "### terraform state: private"
  (cd "$ROOT/terraform/private" && "$TERRAFORM" state list)
} >"$ROOT/logs/terraform-state.txt"

echo
echo "Логи сохранены в lesson14/logs/."
