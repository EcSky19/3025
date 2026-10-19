#!/usr/bin/env bash
# One-step installer for https://3025.mingly.ai/MC1/  (run ON the server as root)
# Downloads the page from this repo. Safe to re-run; never touches mingly.ai's own config.
set -euo pipefail
DOMAIN="3025.mingly.ai"
PAGE_DIR="MC1"
WEB_ROOT="/var/www/3025"
echo "==> Downloading the page from GitHub"
curl -fsSL "https://raw.githubusercontent.com/EcSky19/3025/main/MC1-index.html?$(date +%s)" -o /tmp/mc1-index.html
grep -q "<title>Tagging at Scale</title>" /tmp/mc1-index.html || { echo "Download looks wrong; stopping."; exit 1; }

mkdir -p "$WEB_ROOT/$PAGE_DIR"
install -m 0644 /tmp/mc1-index.html "$WEB_ROOT/$PAGE_DIR/index.html"
rm -f /tmp/mc1-index.html
echo "    Page installed at $WEB_ROOT/$PAGE_DIR/index.html"

if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  ufw allow 80/tcp >/dev/null; ufw allow 443/tcp >/dev/null
fi

caddy_block() {
cat <<EOF

# ENGRC 3025 coursework (added by deploy-mc1.sh)
$DOMAIN {
    root * $WEB_ROOT
    encode gzip
    # Caddy's path matcher ignores case, so the wrong-case-with-slash rule must exclude the exact real path
    @wrongcase {
        path /$PAGE_DIR/
        not path_regexp ^/$PAGE_DIR/\$
    }
    redir @wrongcase   /$PAGE_DIR/ 308
    redir /$PAGE_DIR   /$PAGE_DIR/ 308
    redir /MultimodalContent1* /$PAGE_DIR/ 308
    redir /            /$PAGE_DIR/ 302
    file_server
    header {
        Strict-Transport-Security "max-age=31536000"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
}
EOF
}

port_owner() { ss -ltnp 2>/dev/null | awk '$4 ~ /:(80|443)$/' | grep -oE 'users:\(\("[^"]+' | sed 's/users:(("//' | sort -u | tr '\n' ' '; }

if systemctl is-active --quiet caddy; then
  echo "    Found Caddy already running; adding a site block"
  if ! grep -q "^$DOMAIN {" /etc/caddy/Caddyfile; then
    cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.bak.$(date +%s)"
    caddy_block >> /etc/caddy/Caddyfile
  fi
  caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null
  systemctl reload caddy

elif systemctl is-active --quiet nginx; then
  echo "    Found nginx already running; adding a server block"
  conf="/etc/nginx/sites-available/$DOMAIN"
  if [ ! -f "$conf" ]; then
    cat > "$conf" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    root $WEB_ROOT;
    index index.html;

    location = /                     { return 302 /$PAGE_DIR/; }
    location = /$PAGE_DIR            { return 308 /$PAGE_DIR/; }
    location = /mc1                  { return 308 /$PAGE_DIR/; }
    location = /mc1/                 { return 308 /$PAGE_DIR/; }
    location ^~ /MultimodalContent1  { return 308 /$PAGE_DIR/; }
    location / { try_files \$uri \$uri/ =404; }

    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
EOF
    mkdir -p /etc/nginx/sites-enabled
    ln -sf "$conf" "/etc/nginx/sites-enabled/$DOMAIN"
  fi
  nginx -t
  systemctl reload nginx
  if ! command -v certbot >/dev/null; then
    apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq certbot python3-certbot-nginx
  fi
  certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect

else
  owner="$(port_owner)"
  if [ -n "$owner" ]; then
    echo "    Ports 80/443 are used by: $owner"
    echo "    That isn't Caddy or nginx, so I stopped instead of changing it. The page files are in place;"
    echo "    point that server at $WEB_ROOT for $DOMAIN and re-run this script."
    exit 2
  fi
  echo "    No web server found; installing Caddy"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  if ! apt-get install -y -qq caddy; then
    apt-get install -y -qq debian-keyring debian-archive-keyring apt-transport-https curl gnupg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor --yes -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
    apt-get update -qq && apt-get install -y -qq caddy
  fi
  cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.bak.$(date +%s)" 2>/dev/null || true
  caddy_block > /etc/caddy/Caddyfile
  caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null
  systemctl enable --now caddy
  systemctl reload caddy
fi
echo "==> Checking the live page (HTTPS can take up to a minute the first time)"
for _ in $(seq 1 12); do
  code="$(curl -s -o /dev/null -w '%{http_code}' "https://$DOMAIN/$PAGE_DIR/" || true)"
  [ "$code" = "200" ] && { echo "    LIVE: https://$DOMAIN/$PAGE_DIR"; exit 0; }
  sleep 5
done
echo "    Not answering with 200 yet (last status: ${code:-none})."
echo "    Check that the Hetzner Cloud Firewall (if any) allows TCP 80 and 443, then re-run."
exit 1
