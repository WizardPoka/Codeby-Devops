#!/bin/bash
set -e

DOMAIN="mydevops.local"
WWW_DOMAIN="www.mydevops.local"
CERT_DIR="/etc/ssl/lesson8"

echo "=== Installing Apache + OpenSSL ==="
apt-get update -y
apt-get install -y apache2 openssl

echo "=== Enabling SSL module ==="
a2enmod ssl
a2enmod rewrite
a2enmod headers

echo "=== Creating cert dir ==="
mkdir -p "$CERT_DIR"

echo "=== Generating self-signed certificate ==="
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/server.key" \
    -out "$CERT_DIR/server.crt" \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=DevOps Course/OU=Lesson8/CN=${DOMAIN}" \
    -addext "subjectAltName=DNS:${DOMAIN},DNS:${WWW_DOMAIN}"

chmod 600 "$CERT_DIR/server.key"
chmod 644 "$CERT_DIR/server.crt"

echo "=== Creating content ==="
mkdir -p /var/www/lesson8
cat > /var/www/lesson8/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>HTTPS on ${DOMAIN}</title>
</head>
<body>
    <h1>Secure site: ${DOMAIN}</h1>
    <p>Served over HTTPS from /var/www/lesson8</p>
</body>
</html>
EOF

chown -R www-data:www-data /var/www/lesson8

echo "=== Disabling default site ==="
a2dissite 000-default || true
rm -f /etc/apache2/sites-enabled/000-default.conf

echo "=== HTTP -> HTTPS redirect vhost (port 80) ==="
cat > /etc/apache2/sites-available/redirect-http.conf << EOF
<VirtualHost *:80>
    ServerName ${DOMAIN}
    ServerAlias ${WWW_DOMAIN}

    # www.<domain> -> <domain> + сразу на HTTPS
    RewriteEngine On
    RewriteCond %{HTTP_HOST} ^www\.(.+)$ [NC]
    RewriteRule ^ https://%1%{REQUEST_URI} [R=301,L]

    # всё остальное -> HTTPS
    RewriteRule ^ https://${DOMAIN}%{REQUEST_URI} [R=301,L]
</VirtualHost>
EOF

a2ensite redirect-http

echo "=== HTTPS vhost (port 443) ==="
cat > /etc/apache2/sites-available/https-site.conf << EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName ${DOMAIN}
    ServerAlias ${WWW_DOMAIN}
    DocumentRoot /var/www/lesson8

    SSLEngine on
    SSLCertificateFile ${CERT_DIR}/server.crt
    SSLCertificateKeyFile ${CERT_DIR}/server.key

    <Directory /var/www/lesson8>
        Options FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    # www.<domain> -> <domain> (уже на HTTPS)
    RewriteEngine On
    RewriteCond %{HTTP_HOST} ^www\.(.+)$ [NC]
    RewriteRule ^ https://%1%{REQUEST_URI} [R=301,L]

    ErrorLog \${APACHE_LOG_DIR}/lesson8-ssl-error.log
    CustomLog \${APACHE_LOG_DIR}/lesson8-ssl-access.log combined
</VirtualHost>
</IfModule>
EOF

a2ensite https-site

echo "=== Adding ServerName to suppress warning ==="
echo "ServerName ${DOMAIN}" > /etc/apache2/conf-available/servername.conf
a2enconf servername

echo "=== Validating config ==="
apache2ctl configtest

echo "=== Enabling and starting Apache ==="
systemctl enable apache2
systemctl restart apache2

echo "=== Copy cert to /vagrant for client provisioning ==="
cp "$CERT_DIR/server.crt" /vagrant/scripts/server.crt
chmod 644 /vagrant/scripts/server.crt

echo "=== SERVER done ==="