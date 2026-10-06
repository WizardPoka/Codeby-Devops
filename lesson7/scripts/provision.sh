#!/bin/bash
set -e

echo "=== Installing Apache and Nginx ==="
apt-get update -y
apt-get install -y apache2 nginx

echo "=== Stopping services for reconfiguration ==="
systemctl stop apache2 nginx

echo "=== Removing default configs ==="
# Apache
a2dissite 000-default || true
rm -f /etc/apache2/sites-enabled/000-default.conf
# Nginx
rm -f /etc/nginx/sites-enabled/default

echo "=== Creating content dirs ==="
mkdir -p /opt/apache/www /opt/nginx/www

cat > /opt/apache/www/test.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Apache on 8084</title>
</head>
<body>
    <h1>Hello from Apache!</h1>
    <p>Served on port 8084 from /opt/apache/www</p>
</body>
</html>
EOF

cat > /opt/nginx/www/test.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Nginx on 8085</title>
</head>
<body>
    <h1>Hello from Nginx!</h1>
    <p>Served on port 8085 from /opt/nginx/www</p>
</body>
</html>
EOF

echo "=== Configuring Apache on 8084 ==="
# Меняем порт в ports.conf
sed -i 's/^Listen 80/Listen 8084/' /etc/apache2/ports.conf

# Создаём site config с явным разрешением доступа к /opt/apache/www
cat > /etc/apache2/sites-available/apache-test.conf << 'EOF'
<VirtualHost *:8084>
    ServerAdmin admin@localhost
    DocumentRoot /opt/apache/www

    <Directory /opt/apache/www>
        Options FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    DirectoryIndex test.html index.html

    ErrorLog ${APACHE_LOG_DIR}/apache-test-error.log
    CustomLog ${APACHE_LOG_DIR}/apache-test-access.log combined
</VirtualHost>
EOF

a2ensite apache-test
apache2ctl configtest

# Права на директорию для www-data
chown -R www-data:www-data /opt/apache/www
chmod -R 755 /opt/apache/www

echo "=== Configuring Nginx on 8085 ==="
cat > /etc/nginx/sites-available/nginx-test << 'EOF'
server {
    listen 8085;
    listen [::]:8085;
    root /opt/nginx/www;
    index test.html index.html;
    server_name _;
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

ln -sf /etc/nginx/sites-available/nginx-test /etc/nginx/sites-enabled/nginx-test
nginx -t

echo "=== Enabling autostart ==="
systemctl enable apache2 nginx

echo "=== Starting services ==="
systemctl restart apache2 nginx

echo "=== Done. Check: ==="
echo "  http://localhost:8084  (Apache)"
echo "  http://localhost:8085  (Nginx)"