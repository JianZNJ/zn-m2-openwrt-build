#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part3.sh
# Description: OpenWrt DIY script part 3 (After Install feeds)
#

# Modify default IP -> 192.168.2.1
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

#修改版本信息
sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='OpenWrt IPQ6000 ZN-M2 (build time: $(date +%Y%m%d))'/g"  package/base-files/files/etc/openwrt_release
# 替换golang版本为1.26
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 27.x feeds/packages/lang/golang

# ttyd免登陆
sed -i -r 's#/bin/login#/bin/login -f root#g' feeds/packages/utils/ttyd/files/ttyd.config

# 使用 OpenClash：保持 design 主题默认的 openclash 导航项，不再替换为 passwall
#sed -i -r "s#navbar_proxy = 'openclash'#navbar_proxy = 'passwall'#g" feeds/luci/themes/luci-theme-design/luasrc/view/themes/design/header.htm

# 默认 root 密码设为 password（首次启动执行一次）
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-set-root-password <<'EOFPW'
#!/bin/sh
[ -f /etc/.rootpw_done ] && exit 0
echo -e 'password\npassword' | passwd root >/dev/null 2>&1
touch /etc/.rootpw_done
exit 0
EOFPW
chmod +x files/etc/uci-defaults/99-set-root-password
