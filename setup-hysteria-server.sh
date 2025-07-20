#!/bin/bash

echo "=== Created by M.Reza Hoseiny Nasab ==="
echo "=== Hysteria Server Setup ==="

# Argument parser
WITH_DOMAIN=false
for arg in "$@"; do
  if [ "$arg" == "--with-domain" ]; then
    WITH_DOMAIN=true
  fi
done

read -p "🛡️ Enter strong password for auth (Could be anything, just provide it to the clients): " AUTH_PASSWORD
read -p "🧅 Enter obfuscation password (Could be anything, just provide it to the clients): " OBFS_PASSWORD

# If --with-domain, get domain
if [ "$WITH_DOMAIN" = true ]; then
  read -p "🌐 Enter your domain (e.g., example.com): " DOMAIN
fi

echo "📥 Downloading Hysteria..."
wget https://raw.githubusercontent.com/mrhn3242/WgOverHysteria/main/hysteria-linux-amd64 -O /usr/local/bin/hysteria
chmod +x /usr/local/bin/hysteria

echo "📁 Creating certs..."
mkdir -p /etc/hysteria
openssl ecparam -genkey -name prime256v1 -out /etc/hysteria/private.key
openssl req -new -x509 -days 3650 -key /etc/hysteria/private.key -out /etc/hysteria/cert.pem -subj "/CN=hysteria"

echo "📝 Writing config file..."
cat > /etc/hysteria/config.yaml <<EOF
listen: :443

tls:
  cert: /etc/hysteria/cert.pem
  key: /etc/hysteria/private.key
  alpn:
    - h3
    - h2

auth:
  type: password
  password: $AUTH_PASSWORD

quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 30s
  maxIncomingStreams: 1024
  disablePathMTUDiscovery: false

obfs:
  type: salamander
  salamander:
    password: $OBFS_PASSWORD

udp:
  idle_timeout: 30s

fallback:
  server: 127.0.0.1:8080
  alpn: h2
EOF

# NGINX Setup if needed
if [ "$WITH_DOMAIN" = true ]; then
echo "🌐 Installing nginx and PHP..."
apt install nginx php-fpm -y

echo "📝 Creating PHP abuse-check page..."
mkdir -p /var/www/html
cat > /var/www/html/index.php <<'PHP'
<!DOCTYPE html>
<html>
<head>
    <title>Abuse Check</title>
</head>
<body style="background-color: #eaffea; text-align: center; font-family: Arial;">
    <h1 style="color: green;">✅ Your IP Address is fine</h1>
    <p>Your IP was not found on our database as a bad IP</p>
</body>
</html>
PHP 

PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')

echo "🛠 Configuring nginx to support PHP..."
cat > /etc/nginx/sites-available/fallback-site <<NGINX
server {
    listen 8080 ssl;
    server_name $DOMAIN;

    root /var/www/html;
    index index.php index.html;

    ssl_certificate /etc/hysteria/cert.pem;
    ssl_certificate_key /etc/hysteria/private.key;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$PHP_VERSION-fpm.sock;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/fallback-site /etc/nginx/sites-enabled/fallback-site
nginx -t && systemctl reload nginx
fi

echo "🚀 Running hysteria server..."

pkill -f hysteria 2>/dev/null || true
nohup hysteria server -c /etc/hysteria/config.yaml > /var/log/hysteria.log 2>&1 &

echo "✅ Hysteria Server setup complete."

if [ "$WITH_DOMAIN" = true ]; then
  echo "✅ NGINX fallback site ready for $DOMAIN."

echo "🌐 Installing sniproxy for TCP/443 passthrough..."
apt install sniproxy -y

echo "🧹 Removing default sniproxy config..."
rm -f /etc/sniproxy.conf

echo "📝 Writing new sniproxy config..."
cat > /etc/sniproxy.conf <<EOF
user daemon
pidfile /var/run/sniproxy.pid

error_log {
    syslog daemon
    priority notice
}

listen 443 {
    proto tls
    table https_hosts
}

table https_hosts {
    $DOMAIN 127.0.0.1:8080
    * 127.0.0.1:8080
}
EOF

echo "🔁 Restarting sniproxy..."
systemctl enable sniproxy
systemctl restart sniproxy

echo "✅ sniproxy is running on TCP/443 and forwarding to nginx fallback."
fi