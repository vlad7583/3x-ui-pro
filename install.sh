#!/bin/bash

log_ok() {
    echo -e "\e[1;32m$1\e[0m";
}

log_err() {
    echo -e "\e[1;31m$1\e[0m";
}

log_info() {
    echo -e "\e[1;34m$1\e[0m";
}

gen_port() {
    echo $(( ((RANDOM<<15)|RANDOM) % 55536 + 10000 ))
}

gen_string() {
    echo "$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c "$1")"
}

gen_string_rng() {
    echo "$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c "$(shuf -i "$1" -n 1)")"
}

install_dependencies() {

apt update -y
apt install curl sqlite3 git certbot nginx-full ufw -y

} # install_dependencies

setup_3xui() {

local domain="$1"
local panel_username="$2"
local panel_password="$3"
local panel_path="$4"
local panel_port="$5"
local subscription_path="$6"
local subscription_port="$7"
local vless_ws_path="$8"
local vless_ws_port="$9"
local vless_httpupgrade_path="$10"
local vless_httpupgrade_port="$11"

rm -f /etc/systemd/system/x-ui.service
rm -rf /etc/x-ui
rm -rf /usr/local/x-ui
rm -rf /usr/bin/x-ui

echo "n\n" | bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
x-ui stop

local client_id1=$(/usr/local/x-ui/bin/xray-linux-amd64 uuid)
local client_id2=$(/usr/local/x-ui/bin/xray-linux-amd64 uuid)
local sub_id=$(gen_string 16)
sqlite3 /etc/x-ui/x-ui.db << EOF
DELETE FROM settings WHERE key="webCertFile" OR key="webKeyFile";
INSERT INTO settings (key, value) VALUES ("subEnable", "true");
INSERT INTO settings (key, value) VALUES ("subPath", "/${subscription_path}/");
INSERT INTO settings (key, value) VALUES ("subPort", "${subscription_port}");
INSERT INTO settings (key, value) VALUES ("subURI", "https://${domain}/${subscription_path}/");
INSERT INTO client_traffics (inbound_id, enable, email, up, down, all_time, expiry_time, total) VALUES (1, 1, "first-ws", 0, 0, 0, 0, 0);
INSERT INTO client_traffics (inbound_id, enable, email, up, down, all_time, expiry_time, total) VALUES (2, 1, "first-httpupgrade", 0, 0, 0, 0, 0);
INSERT INTO inbounds (user_id, up, down, total, remark, enable, expiry_time, listen, port, protocol, settings, stream_settings, tag, sniffing) VALUES (
1,
0,
0,
0,
"",
1,
0,
"",
${vless_ws_port},
"vless",
'{
  "clients": [
    {
      "id": "${client_id1}",
      "security": "",
      "password": "",
      "flow": "",
      "email": "first-ws",
      "limitIp": 0,
      "totalGB": 0,
      "expiryTime": 0,
      "enable": true,
      "tgId": 0,
      "subId": "me-${sub_id}",
      "comment": "",
      "reset": 0,
      "created_at": 0,
      "updated_at": 0
    }
  ],
  "decryption": "none",
  "encryption": "none"
}',
'{
  "network": "ws",
  "security": "none",
  "externalProxy": [
    {
      "forceTls": "tls",
      "dest": "${domain}",
      "port": 443,
      "remark": ""
    }
  ],
  "wsSettings": {
    "acceptProxyProtocol": false,
    "path": "/${vless_ws_path}",
    "host": "",
    "headers": {},
    "heartbeatPeriod": 15
  }
}',
"inbound-${vless_ws_port}",
'{
  "enabled": true,
  "destOverride": [
    "http",
    "tls",
    "quic",
    "fakedns"
  ],
  "metadataOnly": false,
  "routeOnly": false
}'
);
INSERT INTO inbounds (user_id, up, down, total, remark, enable, expiry_time, listen, port, protocol, settings, stream_settings, tag, sniffing) VALUES (
1,
0,
0,
0,
"",
1,
0,
"",
${vless_httpupgrade_port},
"vless",
'{
  "clients": [
    {
      "id": "${client_id2}",
      "security": "",
      "password": "",
      "flow": "",
      "email": "first-httpupgrade",
      "limitIp": 0,
      "totalGB": 0,
      "expiryTime": 0,
      "enable": true,
      "tgId": 0,
      "subId": "me-${sub_id}",
      "comment": "",
      "reset": 0,
      "created_at": 0,
      "updated_at": 0
    }
  ],
  "decryption": "none",
  "encryption": "none"
}',
'{
  "network": "httpupgrade",
  "security": "none",
  "externalProxy": [
    {
      "forceTls": "tls",
      "dest": "${domain}",
      "port": 443,
      "remark": ""
    }
  ],
  "httpupgradeSettings": {
    "acceptProxyProtocol": false,
    "path": "/${vless_httpupgrade_path}",
    "host": "",
    "headers": {}
  }
}',
"inbound-${vless_httpupgrade_port}",
'{
  "enabled": false,
  "destOverride": [
    "http",
    "tls",
    "quic",
    "fakedns"
  ],
  "metadataOnly": false,
  "routeOnly": false
}'
);
EOF

/usr/local/x-ui/x-ui setting -webBasePath "${panel_path}" -port "${panel_port}" -username "${panel_username}" -password "${panel_password}"
x-ui start
x-ui enable

} # setup_3xui

setup_dummy() {

rm -rf /var/www/html/dummy
git clone https://github.com/leshark/nometa.git /var/www/html/dummy

} # setup_dummy

setup_domain() {

certbot certonly --standalone --non-interactive --agree-tos --register-unsafely-without-email -d "$1"

} # setup_domain

setup_nginx() {

local domain="$1"
local panel_path="$2"
local panel_port="$3"
local subscription_path="$4"
local subscription_port="$5"
local vless_ws_path="$6"
local vless_ws_port="$7"
local vless_httpupgrade_path="$8"
local vless_httpupgrade_port="$9"

systemctl stop nginx
systemctl disable nginx

rm -f "/etc/nginx/sites-available/default"
rm -f "/etc/nginx/sites-available/{80,xray}.conf"
find "/etc/nginx/sites-enabled/" -mindepth 1 -maxdepth 1 -delete

cat > "/etc/nginx/sites-available/80.conf" << EOF
server {
    listen 80;
    return 301 https://\$host\$request_uri;
}
EOF

cat > "/etc/nginx/sites-available/xray.conf" << EOF
server {
    server_name ${domain};

    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/${domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain}/privkey.pem;

    # 3X-UI Panel
    location /${panel_path} {
        proxy_pass http://127.0.0.1:${panel_port};
        proxy_redirect off;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Subscription
    location /${subscription_path} {
        proxy_pass http://127.0.0.1:${subscription_port};
        proxy_redirect off;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # VLESS WebSocket
    location /${vless_ws_path} {
        proxy_pass http://127.0.0.1:${vless_ws_port};
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # VLESS HTTPUpgrade
    location /${vless_httpupgrade_path} {
        proxy_pass http://127.0.0.1:${vless_httpupgrade_port};
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Dummy Site
    location / {
        root /var/www/html/dummy;
        index index.html =404;
    }
}
EOF

ln -s "/etc/nginx/sites-available/80.conf" "/etc/nginx/sites-enabled/"
ln -s "/etc/nginx/sites-available/xray.conf" "/etc/nginx/sites-enabled/"

systemctl enable nginx
systemctl start nginx

} # setup_nginx

setup_ufw() {

ufw disable
ufw --force reset
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable

} # setup_ufw

[[ $EUID -ne 0 ]] && log_err "please run as sudo or root" && exit 1;

_DOMAIN="$1"
_PANEL_USERNAME="admin"
_PANEL_PASSWORD=$(gen_string 12)
_PANEL_PATH=$(gen_string_rng 18-24)
_PANEL_PORT=$(gen_port)
_SUBSCRIPTION_PATH=$(gen_string_rng 18-24)
_SUBSCRIPTION_PORT=$(gen_port)
_VLESS_WS_PATH=$(gen_string_rng 18-24)
_VLESS_WS_PORT=$(gen_port)
_VLESS_HTTPUPGRADE_PATH=$(gen_string_rng 18-24)
_VLESS_HTTPUPGRADE_PORT=$(gen_port)

while true; do
    if [[ -n "$_DOMAIN" ]]; then
        break
    fi
    echo -en "Enter domain: " && read _DOMAIN
done

log_info "[ Domain: ${_DOMAIN} ]"
log_info "[ Installing Dependencies ]"
install_dependencies
log_info "[ Setting up 3X-UI ]"
setup_3xui "$_DOMAIN" "$_PANEL_USERNAME" "$_PANEL_PASSWORD" "$_PANEL_PATH" "$_PANEL_PORT" "$_SUBSCRIPTION_PATH" "$_SUBSCRIPTION_PORT" "$_VLESS_WS_PATH" "$_VLESS_WS_PORT" "$_VLESS_HTTPUPGRADE_PATH" "$_VLESS_HTTPUPGRADE_PORT"
log_info "[ Setting up Dummy Site ]"
setup_dummy
log_info "[ Setting up Domain ]"
setup_domain "$_DOMAIN"
log_info "[ Setting up Nginx ]"
setup_nginx "$_DOMAIN" "$_PANEL_PATH" "$_PANEL_PORT" "$_SUBSCRIPTION_PATH" "$_SUBSCRIPTION_PORT" "$_VLESS_WS_PATH" "$_VLESS_WS_PORT" "$_VLESS_HTTPUPGRADE_PATH" "$_VLESS_HTTPUPGRADE_PORT"
log_info "[ Setting up Firewall ]"
setup_ufw

log_ok "[ Successfully Installed Proxy ]"
log_ok "URL: https://${_DOMAIN}/${_PANEL_PATH}/"
log_ok "Username: ${_PANEL_USERNAME}"
log_ok "Password: ${_PANEL_PASSWORD}"
