#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# File name: diy-part3.sh
# Description: OpenWrt DIY script part 3 (After Install feeds)
#

echo "==> 1. Default IP -> 192.168.2.1"
sed -i 's/192\.168\.1\.1/192.168.2.1/g' package/base-files/files/bin/config_generate

echo "==> 2. Version info"
sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='OpenWrt IPQ6000 ZN-M2 (build time: $(date +%Y%m%d))'/g" package/base-files/files/etc/openwrt_release

echo "==> 3. golang 27.x"
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 27.x feeds/packages/lang/golang

echo "==> 4. ttyd passwordless login"
sed -i -r 's#/bin/login#/bin/login -f root#g' feeds/packages/utils/ttyd/files/ttyd.config

echo "==> 5. Keep design theme openclash navbar entry (no passwall rewrite)"

mkdir -p files/etc/uci-defaults

echo "==> 6. Root password -> Za831021."
cat > files/etc/uci-defaults/99-set-root-password <<'EOF'
#!/bin/sh
[ -f /etc/.rootpw_done ] && exit 0
echo -e 'Za831021.\nZa831021.' | passwd root >/dev/null 2>&1
touch /etc/.rootpw_done
exit 0
EOF
chmod +x files/etc/uci-defaults/99-set-root-password

echo "==> 7. Network: eth0=WAN(PPPoE), eth1-3=LAN bridge 192.168.2.1"
cat > files/etc/uci-defaults/97-network <<'EOF'
#!/bin/sh
# ZN-M2 (zn,m2): WAN=eth0, LAN=eth1/eth2/eth3

uci -q set network.wan=interface
uci -q set network.wan.device='eth0'
uci -q set network.wan.proto='pppoe'
uci -q set network.wan.username='njkd107257593'
uci -q set network.wan.password='84318564'
uci -q set network.wan.ipv6='0'

uci -q set network.wan6=interface
uci -q set network.wan6.device='eth0'
uci -q set network.wan6.proto='dhcpv6'
uci -q set network.wan6.auto='0'

uci -q set network.lan.device='br-lan'
uci -q set network.lan.proto='static'
uci -q set network.lan.ipaddr='192.168.2.1'
uci -q set network.lan.netmask='255.255.255.0'

existing=$(uci -q get network.@device[0].name || true)
if [ "$existing" = "br-lan" ]; then
    uci -q delete network.@device[0].ports
    dev="network.@device[0]"
else
    sec=$(uci add network device)
    uci -q set "network.$sec.name"='br-lan'
    uci -q set "network.$sec.type"='bridge'
    dev="network.$sec"
fi
uci -q add_list "$dev.ports"='eth1'
uci -q add_list "$dev.ports"='eth2'
uci -q add_list "$dev.ports"='eth3'

uci -q commit network
exit 0
EOF
chmod +x files/etc/uci-defaults/97-network

echo "==> 8. Pre-bake OpenClash core (linux-arm64, for IPQ6000)"
CORE_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz"
mkdir -p files/etc/openclash/core
CORE_TMP=$(mktemp -d)
if curl -fsSL --retry 3 --connect-timeout 20 -o "$CORE_TMP/core.tar.gz" "$CORE_URL"; then
  if tar -xzf "$CORE_TMP/core.tar.gz" -C "$CORE_TMP" && [ -f "$CORE_TMP/clash" ]; then
    install -m 0755 "$CORE_TMP/clash" files/etc/openclash/core/clash_meta
    echo "    core installed: $(du -h files/etc/openclash/core/clash_meta | cut -f1)"
  else
    echo "    WARN: extract failed or clash binary missing"
  fi
else
  echo "    WARN: core download failed (manual download needed on first boot)"
fi
rm -rf "$CORE_TMP"

echo "==> 9. Build number + OTA tool + weekly check"
mkdir -p files/etc files/usr/sbin files/etc/crontabs
echo "${GITHUB_RUN_NUMBER:-0}" > files/etc/fw-version
echo "    build number: $(cat files/etc/fw-version)"
install -m 0755 "$GITHUB_WORKSPACE/scripts/zn-m2/fw-ota.sh" files/usr/sbin/fw-ota
cat > files/etc/crontabs/root <<'EOF'
# 每周六 04:00 检查固件更新（只检查，不自动刷）
0 4 * * 6 /usr/sbin/fw-ota check >> /var/log/fw-ota.log 2>&1
EOF
chmod 600 files/etc/crontabs/root

echo "==> 10. Enable adblock / banip / oaf on first boot"
cat > files/etc/uci-defaults/96-services <<'EOF'
#!/bin/sh
for s in adblock banip appfilter oaf; do
    if [ -x "/etc/init.d/$s" ]; then
        "/etc/init.d/$s" enable >/dev/null 2>&1
        "/etc/init.d/$s" restart >/dev/null 2>&1
    fi
done
exit 0
EOF
chmod +x files/etc/uci-defaults/96-services

echo "==> 11. Custom overlay files"
find files -type f | sed 's/^/    /'
echo "==> diy-part3 done"
