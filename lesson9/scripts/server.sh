#!/bin/bash
set -e

echo "=== SERVER provisioning ==="

# --- MySQL ---
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y mysql-server rsync

systemctl enable mysql
systemctl start mysql

# --- Создаём БД, таблицы, данные ---
mysql <<'SQL'
CREATE DATABASE IF NOT EXISTS lesson9db;
USE lesson9db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'new',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO users (name, email) VALUES
    ('Alice',   'alice@example.com'),
    ('Bob',     'bob@example.com'),
    ('Charlie', 'charlie@example.com');

INSERT INTO orders (user_id, amount, status) VALUES
    (1, 100.50, 'paid'),
    (2, 250.00, 'new'),
    (3, 75.25,  'shipped');
SQL

echo "=== DB and tables created ==="

# --- Скрипт бэкапа ---
mkdir -p /opt/mysql_backup
cp /vagrant/scripts/mysql_backup.sh /opt/mysql_backup/mysql_backup.sh
chmod +x /opt/mysql_backup/mysql_backup.sh

# --- Ожидание store_key ---
MAX_WAIT=180
WAITED=0
while [ ! -f /vagrant/scripts/store_key ] && [ $WAITED -lt $MAX_WAIT ]; do
    echo "Waiting for store_key... ($WAITED/$MAX_WAIT)"
    sleep 5
    WAITED=$((WAITED + 5))
done

if [ ! -f /vagrant/scripts/store_key ]; then
    echo "ERROR: store_key not found!"
    exit 1
fi

# Кладём приватный ключ от store на server
mkdir -p /root/.ssh
cp /vagrant/scripts/store_key /root/.ssh/store_key
chmod 600 /root/.ssh/store_key

# Настраиваем SSH config для удобства
cat > /root/.ssh/config << 'EOF'
Host store
    HostName 192.168.56.11
    User vagrant
    IdentityFile /root/.ssh/store_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
chmod 600 /root/.ssh/config

# Добавим store в /etc/hosts
grep -q "192.168.56.11 store" /etc/hosts || echo "192.168.56.11 store" >> /etc/hosts

# --- Cron: бэкап раз в час ---
# cron-задание от root: mysqldump + rsync
cat > /etc/cron.d/mysql_backup << 'EOF'
# Бэкап MySQL и rsync на store — каждый час
0 * * * * root /opt/mysql_backup/mysql_backup.sh >> /var/log/mysql_backup.log 2>&1
EOF

chmod 644 /etc/cron.d/mysql_backup

# --- Запустим бэкап один раз сейчас, чтобы был результат ---
/opt/mysql_backup/mysql_backup.sh

echo "=== SERVER done ==="