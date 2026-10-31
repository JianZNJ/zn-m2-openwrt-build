#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

echo "==> Fetch luci-app-banip from upstream openwrt/luci (openwrt-21.02)"
rm -rf /tmp/luci-banip package/luci-app-banip
BANIP_OK=0
if git clone --depth 1 --filter=blob:none --sparse -b openwrt-21.02 \
      https://github.com/openwrt/luci.git /tmp/luci-banip 2>/dev/null; then
  ( cd /tmp/luci-banip && git sparse-checkout set applications/luci-app-banip ) || true
  if [ -d /tmp/luci-banip/applications/luci-app-banip ]; then
    cp -r /tmp/luci-banip/applications/luci-app-banip package/luci-app-banip
    BANIP_OK=1
  fi
fi
if [ "$BANIP_OK" = "1" ]; then
  echo "    luci-app-banip OK"
else
  echo "    WARN: luci-app-banip fetch failed"
fi
rm -rf /tmp/luci-banip

echo "==> feeds:"
cat feeds.conf.default