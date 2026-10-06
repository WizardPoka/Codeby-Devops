#!/bin/bash
set -e

DOMAIN="mydevops.local"
SERVER_IP="192.168.56.10"

echo "=== Waiting for server.crt from server VM ==="
MAX_WAIT=180
WAITED=0
while [ ! -f /vagrant/scripts/server.crt ] && [ $WAITED -lt $MAX_WAIT ]; do
    echo "Waiting for /vagrant/scripts/server.crt... ($WAITED/$MAX_WAIT)"
    sleep 5
    WAITED=$((WAITED + 5))
done

if [ ! -f /vagrant/scripts/server.crt ]; then
    echo "ERROR: server.crt not found!"
    exit 1
fi

echo "=== Adding ${DOMAIN} to /etc/hosts ==="
# Убираем старые записи, если есть
sed -i "/${DOMAIN}/d" /etc/hosts
echo "${SERVER_IP} ${DOMAIN} www.${DOMAIN}" >> /etc/hosts

echo "=== Installing the self-signed cert as trusted ==="
cp /vagrant/scripts/server.crt /usr/local/share/ca-certificates/lesson8-server.crt
update-ca-certificates

echo "=== Testing HTTPS from client ==="
# --cacert можно не указывать, так как уже добавили в trusted
curl -sS https://${DOMAIN}/ | head -5 || echo "curl failed"

echo "=== CLIENT done ==="
echo "Check: curl https://${DOMAIN}/"