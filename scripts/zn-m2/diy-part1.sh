#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

echo "==> Clone OpenAppFilter (kmod-oaf + appfilter + luci-app-oaf)"
rm -rf package/OpenAppFilter
git clone --depth 1 https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter

# 4.4 内核没有 fallthrough 宏（Linux 5.x 才引入），补一个空定义
if [ -f package/OpenAppFilter/oaf/Makefile ]; then
  sed -i 's/^KCFLAGS := /KCFLAGS := -Dfallthrough= /' package/OpenAppFilter/oaf/Makefile
  echo "    patched KCFLAGS:"
  grep -n 'KCFLAGS :=' package/OpenAppFilter/oaf/Makefile | head -2
fi
echo "    contents:"
ls -1 package/OpenAppFilter

echo "==> Fetch luci-app-banip from upstream openwrt/luci (openwrt-21.02)"
# fork 的 luci 源缺少该包，单独从上游补进来
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

if [ "$BANIP_OK" != "1" ]; then
  echo "    sparse clone failed, trying shallow full clone..."
  rm -rf /tmp/luci-banip
  if git clone --depth 1 -b openwrt-21.02 https://github.com/openwrt/luci.git /tmp/luci-banip 2>/dev/null; then
    if [ -d /tmp/luci-banip/applications/luci-app-banip ]; then
      cp -r /tmp/luci-banip/applications/luci-app-banip package/luci-app-banip
      BANIP_OK=1
    fi
  fi
fi

if [ "$BANIP_OK" = "1" ]; then
  echo "    luci-app-banip OK:"
  ls -1 package/luci-app-banip
else
  echo "    WARN: luci-app-banip fetch failed, banip will be CLI-only"
fi
rm -rf /tmp/luci-banip

echo "==> feeds:"
cat feeds.conf.default
