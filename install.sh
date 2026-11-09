#!/usr/bin/env bash
# Publishes the site in this repo at https://3025.mingly.ai (run on the server as root).
# Safe to re-run: it swaps in the latest site and only touches the 3025.mingly.ai nginx config.
set -euo pipefail

DOMAIN="3025.mingly.ai"
REPO_TAR="https://codeload.github.com/EcSky19/3025/tar.gz/refs/heads/main"
WEB_ROOT="/var/www/3025"
CONF="/etc/nginx/sites-available/$DOMAIN"

echo "==> Downloading the site from GitHub"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL "$REPO_TAR?$(date +%s)" | tar -xz -C "$tmp" --strip-components=1
[ -f "$tmp/site/index.html" ] && grep -q "Ethan Coskay" "$tmp/site/index.html" || { echo "Download looks wrong; stopping."; exit 1; }

echo "==> Installing the site"
mkdir -p "$WEB_ROOT"
rm -rf "$WEB_ROOT/site.new"
cp -r "$tmp/site" "$WEB_ROOT/site.new"
find "$WEB_ROOT/site.new" -type d -exec chmod 755 {} +
find "$WEB_ROOT/site.new" -type f -exec chmod 644 {} +
if [ -d "$WEB_ROOT/site" ]; then mv "$WEB_ROOT/site" "$WEB_ROOT/site.old"; fi
mv "$WEB_ROOT/site.new" "$WEB_ROOT/site"
rm -rf "$WEB_ROOT/site.old"
echo "    $(find "$WEB_ROOT/site" -name index.html | wc -l) pages installed at $WEB_ROOT/site"

command -v nginx >/dev/null && systemctl is-active --quiet nginx || { echo "nginx isn't running on this server; stopping."; exit 1; }

echo "==> Configuring nginx for $DOMAIN"
backup=""
if [ -f "$CONF" ]; then backup="/root/$DOMAIN.nginx.bak.$(date +%s)"; cp "$CONF" "$backup"; fi
cat > "$CONF" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    root $WEB_ROOT/site;
    index index.html;

    # Earlier links to the case study keep working
    location ~* ^/mc1/?\$                  { return 301 /projects/tagging-at-scale/; }
    location ~* ^/multimodalcontent1/?\$   { return 301 /projects/tagging-at-scale/; }

    location / { try_files \$uri \$uri/ =404; }
    error_page 404 /404.html;

    gzip on;
    gzip_types text/css application/javascript image/svg+xml application/xml;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
EOF
ln -sf "$CONF" "/etc/nginx/sites-enabled/$DOMAIN"
if ! nginx -t; then
  echo "    nginx rejected the new config; restoring the previous one so nothing else is affected."
  if [ -n "$backup" ]; then cp "$backup" "$CONF"; else rm -f "$CONF" "/etc/nginx/sites-enabled/$DOMAIN"; fi
  nginx -t && systemctl reload nginx
  exit 1
fi
systemctl reload nginx

echo "==> HTTPS"
if ! command -v certbot >/dev/null; then
  apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq certbot python3-certbot-nginx
fi
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect --keep-until-expiring

echo "==> Checking the live site"
ok=1
for path in / /about/ /projects/ /projects/tagging-at-scale/ /work-experience/ /assets/Ethan_Coskay_Resume.pdf; do
  code="$(curl -s -o /dev/null -w '%{http_code}' "https://$DOMAIN$path" || true)"
  printf '    %-36s %s\n' "$path" "$code"
  [ "$code" = "200" ] || ok=0
done
mc1="$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' "https://$DOMAIN/MC1" || true)"
printf '    %-36s %s\n' "/MC1" "$mc1"
if [ "$ok" = 1 ]; then echo "    LIVE: https://$DOMAIN"; else echo "    Some pages didn't return 200; paste this output back."; exit 1; fi
