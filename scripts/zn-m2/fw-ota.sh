#!/bin/sh
# ============================================================
#  fw-ota — ZN-M2 固件在线升级（GitHub Releases）
#
#  用法:
#    fw-ota check    检查是否有新版本
#    fw-ota update   下载 + 校验 + 确认后刷机
#    fw-ota force    下载 + 校验后直接刷机
#    fw-ota version  显示本地版本
# ============================================================
set -u

REPO="JianZNJ/zn-m2-openwrt-build"
API="https://api.github.com/repos/${REPO}"
VERFILE="/etc/fw-version"
WORKDIR="/tmp/fw-ota"

log() { echo "[fw-ota] $*"; }

local_ver() {
    if [ -f "$VERFILE" ]; then
        cat "$VERFILE" 2>/dev/null
    else
        echo 0
    fi
}

fetch_url() {
    if command -v uclient-fetch >/dev/null 2>&1; then
        if [ "$2" = "-" ]; then
            uclient-fetch -q -O - "$1" 2>/dev/null
        else
            uclient-fetch -q -O "$2" "$1" 2>/dev/null
        fi
    elif command -v curl >/dev/null 2>&1; then
        if [ "$2" = "-" ]; then
            curl -fsSL --max-time 60 "$1" 2>/dev/null
        else
            curl -fsSL --max-time 900 -o "$2" "$1" 2>/dev/null
        fi
    else
        if [ "$2" = "-" ]; then
            wget -q -O - "$1" 2>/dev/null
        else
            wget -q -O "$2" "$1" 2>/dev/null
        fi
    fi
}

get_release_json() {
    fetch_url "$API/releases?per_page=1" -
}

version_from_tag() {
    # tag 形如 OpenClash-0.45.152-beta-r1234
    echo "$1" | sed -n 's/.*-r\([0-9][0-9]*\)$/\1/p'
}

do_check() {
    json=$(get_release_json)
    if [ -z "$json" ]; then
        log "无法访问 GitHub API（检查网络/DNS）"
        return 2
    fi
    tag=$(echo "$json" | jsonfilter -e '@[0].tag_name' 2>/dev/null)
    if [ -z "$tag" ]; then
        log "解析 release tag 失败"
        return 2
    fi
    lv=$(local_ver)
    rv=$(version_from_tag "$tag")
    if [ -z "$rv" ]; then
        log "tag 格式无版本号（$tag），按有新版本处理"
        return 0
    fi
    log "本地版本: $lv"
    log "远端版本: $rv ($tag)"
    if [ "$rv" -gt "$lv" ] 2>/dev/null; then
        log "=> 有新版本可用"
        return 0
    fi
    log "=> 已是最新"
    return 1
}

do_update() {
    force="${1:-0}"
    json=$(get_release_json)
    [ -z "$json" ] && { log "无法访问 GitHub API"; return 2; }

    tag=$(echo "$json" | jsonfilter -e '@[0].tag_name' 2>/dev/null)
    [ -z "$tag" ] && { log "解析 tag 失败"; return 2; }

    lv=$(local_ver)
    rv=$(version_from_tag "$tag")
    if [ -n "$rv" ] && ! [ "$rv" -gt "$lv" ] 2>/dev/null; then
        log "已是最新（本地 $lv / 远端 $rv）"
        return 0
    fi

    img_url=$(echo "$json" | tr ',' '\n' | grep -o 'https://[^"]*sysupgrade\.bin' | grep -v gecoosac | head -1)
    [ -z "$img_url" ] && img_url=$(echo "$json" | tr ',' '\n' | grep -o 'https://[^"]*sysupgrade\.bin' | head -1)
    [ -z "$img_url" ] && { log "未在 release 中找到 sysupgrade.bin"; return 3; }

    sum_url=$(echo "$json" | tr ',' '\n' | grep -o 'https://[^"]*sha256sums[^"]*' | grep -v gecoosac | head -1)

    log "目标版本: $tag"
    log "固件: $(basename "$img_url")"
    mkdir -p "$WORKDIR"
    fw="$WORKDIR/sysupgrade.bin"

    log "下载中…"
    if ! fetch_url "$img_url" "$fw"; then
        log "下载失败"; return 4
    fi
    [ -s "$fw" ] || { log "下载结果为空"; return 4; }

    if [ -n "$sum_url" ]; then
        sums="$WORKDIR/sha256sums"
        fetch_url "$sum_url" "$sums"
        want=$(basename "$img_url")
        expect=$(grep " $want\$" "$sums" 2>/dev/null | awk '{print $1}' | head -1)
        if [ -n "$expect" ]; then
            actual=$(sha256sum "$fw" | awk '{print $1}')
            if [ "$expect" != "$actual" ]; then
                log "sha256 校验失败！已中止"
                rm -f "$fw"
                return 5
            fi
            log "sha256 校验通过"
        else
            log "警告: sha256sums 中未找到该文件，跳过校验"
        fi
    else
        log "警告: release 无 sha256sums，跳过校验"
    fi

    if [ "$force" != "1" ]; then
        printf "确认刷入 %s 并重启？[y/N] " "$tag"
        read ans
        case "$ans" in
            y|Y|yes|YES) ;;
            *) log "已取消"; rm -f "$fw"; return 0 ;;
        esac
    fi

    log "开始 sysupgrade（保留配置），设备即将重启…"
    sysupgrade "$fw"
}

case "${1:-check}" in
    check)   do_check; exit $? ;;
    update)  do_update 0; exit $? ;;
    force)   do_update 1; exit $? ;;
    version) echo "本地版本: $(local_ver)"; exit 0 ;;
    *)       echo "用法: $0 {check|update|force|version}"; exit 1 ;;
esac
