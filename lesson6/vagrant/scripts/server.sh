#!/bin/bash
# Провижининг для серверной ВМ
set -e

echo "=== Provisioning SERVER ==="

# Создаём пользователя sshuser
if ! id -u sshuser >/dev/null 2>&1; then
    useradd -m -s /bin/bash sshuser
fi

# Создаём .ssh с правильными правами и владельцем
install -d -m 700 -o sshuser -g sshuser /home/sshuser/.ssh

# Генерируем ключ ОТ ИМЕНИ sshuser (ключ важен, чтобы права были верные)
if [ ! -f /home/sshuser/.ssh/id_rsa ]; then
    sudo -u sshuser ssh-keygen -t rsa -b 2048 \
        -f /home/sshuser/.ssh/id_rsa -N "" -q
fi

# Публичный ключ -> authorized_keys
cat /home/sshuser/.ssh/id_rsa.pub > /home/sshuser/.ssh/authorized_keys
chmod 600 /home/sshuser/.ssh/authorized_keys
chown sshuser:sshuser /home/sshuser/.ssh/authorized_keys

# Разрешаем вход по ключу, отключаем пароль
sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

# Копируем приватный ключ в /vagrant, чтобы client его забрал
cp /home/sshuser/.ssh/id_rsa /vagrant/scripts/server_private_key
chmod 600 /vagrant/scripts/server_private_key

echo "=== SERVER provisioning complete ==="