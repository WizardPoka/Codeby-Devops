#!/usr/bin/env bash
# Минимальная подготовка Vagrant-ВМ для Ansible.
# Здесь намеренно НЕ устанавливаются пакеты из задания (wget, htop, nginx):
# их должен установить playbook, иначе задание теряет смысл.

set -euo pipefail

# Ждём cloud-init, чтобы apt не был заблокирован.
if command -v cloud-init >/dev/null 2>&1; then
  cloud-init status --wait || true
fi

# Ansible требует Python на управляемом хосте.
if ! command -v python3 >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y python3
fi
