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
echo "    contents:"
ls -1 package/OpenAppFilter

echo "==> feeds:"
cat feeds.conf.default
