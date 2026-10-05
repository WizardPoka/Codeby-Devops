#!/bin/bash
# Провижининг для клиентской ВМ

set -e

echo "=== Provisioning CLIENT ==="

# Ждём, пока ключ сервера появится в /vagrant
# (server и client поднимаются параллельно, но /vagrant общий)
MAX_WAIT=120
WAITED=0
while [ ! -f /vagrant/scripts/server_private_key ] && [ $WAITED -lt $MAX_WAIT ]; do
    echo "Waiting for server_private_key... ($WAITED/$MAX_WAIT)"
    sleep 5
    WAITED=$((WAITED + 5))
done

if [ ! -f /vagrant/scripts/server_private_key ]; then
    echo "ERROR: server_private_key not found!"
    exit 1
fi

# Копируем приватный ключ сервера на клиент
mkdir -p /home/vagrant/.ssh
cp /vagrant/scripts/server_private_key /home/vagrant/.ssh/server_key
chmod 600 /home/vagrant/.ssh/server_key
chown vagrant:vagrant /home/vagrant/.ssh/server_key

# Настраиваем SSH config для удобного подключения
cat > /home/vagrant/.ssh/config << 'EOF'
Host server
    HostName 192.168.56.10
    User sshuser
    IdentityFile /home/vagrant/.ssh/server_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

chmod 600 /home/vagrant/.ssh/config
chown vagrant:vagrant /home/vagrant/.ssh/config

# Добавляем запись в /etc/hosts для резолва имени "server"
echo "192.168.56.10 server" >> /etc/hosts

echo "=== CLIENT provisioning complete ==="
echo "Now you can run: ssh -i /home/vagrant/.ssh/server_key server"