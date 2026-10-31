#!/bin/bash
echo "==> 1. default IP -> 192.168.2.1"
sed -i 's/192\.168\.1\.1/192.168.2.1/g' package/base-files/files/bin/config_generate

mkdir -p files/etc/uci-defaults

echo "==> 2. root password -> Za831021."
cat > files/etc/uci-defaults/99-set-root-password <<'EOF'
#!/bin/sh
[ -f /etc/.rootpw_done ] && exit 0
echo -e 'Za831021.\nZa831021.' | passwd root >/dev/null 2>&1
touch /etc/.rootpw_done
exit 0
EOF
chmod +x files/etc/uci-defaults/99-set-root-password

echo "==> 3. pre-bake OpenClash core (arm64)"
CORE_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz"
mkdir -p files/etc/openclash/core
CORE_TMP=$(mktemp -d)
if curl -fsSL --retry 3 --connect-timeout 20 -o "$CORE_TMP/core.tar.gz" "$CORE_URL"; then
  if tar -xzf "$CORE_TMP/core.tar.gz" -C "$CORE_TMP" && [ -f "$CORE_TMP/clash" ]; then
    install -m 0755 "$CORE_TMP/clash" files/etc/openclash/core/clash_meta
    echo "    core installed: $(du -h files/etc/openclash/core/clash_meta | cut -f1)"
  else
    echo "    WARN: extract failed"
  fi
else
  echo "    WARN: core download failed"
fi
rm -rf "$CORE_TMP"

echo "==> 4. build number + OTA"
mkdir -p files/etc files/usr/sbin files/etc/crontabs
echo "${GITHUB_RUN_NUMBER:-0}" > files/etc/fw-version
install -m 0755 "$GITHUB_WORKSPACE/scripts/zn-m2/fw-ota.sh" files/usr/sbin/fw-ota
cat > files/etc/crontabs/root <<'EOF'
# weekly firmware update check
0 4 * * 6 /usr/sbin/fw-ota check >> /var/log/fw-ota.log 2>&1
EOF
chmod 600 files/etc/crontabs/root

echo "==> 5. overlay files"
find files -type f | sed 's/^/    /'