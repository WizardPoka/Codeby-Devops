#!/bin/bash
set -e

echo "=== STORE provisioning ==="

# Папка для приёма бэкапов
mkdir -p /opt/store/mysql
chown -R vagrant:vagrant /opt/store/mysql
chmod -R 755 /opt/store

# Разрешаем vagrant-пользователю принимать rsync по ключу
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh

# Генерируем ключ для server -> store, чтобы server мог rsync'ить
# (альтернативно можно использовать общий ключ через /vagrant)
if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
    sudo -u vagrant ssh-keygen -t rsa -b 2048 -f /home/vagrant/.ssh/id_rsa -N ""
fi

# Публичный ключ кладём в authorized_keys
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Кладём приватный ключ в /vagrant для передачи на server
cp /home/vagrant/.ssh/id_rsa /vagrant/scripts/store_key
chmod 600 /vagrant/scripts/store_key

# Разрешаем SSH по ключу
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

echo "=== STORE done ==="