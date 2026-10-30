#!/bin/bash
set -euo pipefail

MANIFEST=$(ls "$FIRMWARE"/*.manifest | head -1)

# 自动识别代理插件：优先 OpenClash，其次 Passwall
PROXY_NAME=""
PROXY_VER=""

if grep -q "^luci-app-openclash " "$MANIFEST"; then
  PROXY_NAME="OpenClash"
  PROXY_VER=$(grep "^luci-app-openclash " "$MANIFEST" | head -1 | awk -F" - " '{print $2}')
elif grep -q "^luci-app-passwall " "$MANIFEST"; then
  PROXY_NAME="Passwall"
  PROXY_VER=$(grep "^luci-app-passwall " "$MANIFEST" | head -1 | awk -F" - " '{print $2}')
fi

if [ -z "$PROXY_VER" ]; then
  PROXY_NAME="none"
  PROXY_VER="unknown"
  echo "WARNING: no proxy app found in manifest, continuing anyway"
fi

echo "$PROXY_NAME version: $PROXY_VER"
echo "PROXY_VER=$PROXY_VER" >> "$GITHUB_ENV"

TAG="${PROXY_NAME}-${PROXY_VER}-$(date +%Y%m%d%H)"
echo "release_tag=${TAG}" >> "$GITHUB_OUTPUT"

touch release.txt
echo "## ZN-M2 固件" >> release.txt
echo "" >> release.txt
echo "**默认管理地址:** \`192.168.2.1\`  **默认密码:** \`password\`" >> release.txt
echo "" >> release.txt
echo "**代理插件:** $PROXY_NAME \`$PROXY_VER\`" >> release.txt
echo "" >> release.txt
grep xray-core   "$MANIFEST" | awk -F" - " '{print $2}' | awk -F"-" '{print "**Xray:** `"$1"`"}'        >> release.txt || true
grep sing-box    "$MANIFEST" | awk -F" - " '{print $2}' | awk -F"-" '{print "**Sing-Box:** `"$1"`"}'    >> release.txt || true
grep hysteria    "$MANIFEST" | awk -F" - " '{print $2}' | awk -F"-" '{print "**Hysteria:** `"$1"`"}'    >> release.txt || true
grep chinadns-ng "$MANIFEST" | awk -F" - " '{print $2}' | awk -F"-" '{print "**ChinaDNS-NG:** `"$1"`"}' >> release.txt || true
echo "" >> release.txt
echo "### 变体说明" >> release.txt
echo "- **basic**: 纯净版，不含集客AC控制器" >> release.txt
echo "- **gecoosac-v2**: 含集客AC控制器 V2" >> release.txt
echo "" >> release.txt
echo "详细包信息请查看 manifest 文件" >> release.txt

echo "release_name=ZN-M2 ${PROXY_NAME} ${PROXY_VER}" >> "$GITHUB_OUTPUT"