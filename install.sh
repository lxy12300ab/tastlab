#!/bin/bash
# 安装 Taste Lab（launchd 常驻，macOS）
# 用法：bash install.sh
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
LABEL="com.local.appdesk-taste-lab"
SRC="$ROOT/launchd/${LABEL}.plist"
DEST="$HOME/Library/LaunchAgents/${LABEL}.plist"

[ -f "$SRC" ] || { echo "缺少 plist 模板：$SRC"; exit 1; }

sed -e "s#__REPO_ROOT__#${ROOT}#g" -e "s#__HOME__#${HOME}#g" "$SRC" > "$DEST"

launchctl unload "$DEST" 2>/dev/null || true
launchctl load "$DEST"
echo "已安装并启动：${LABEL}"
echo "  程序：${ROOT}/apps/taste-lab"
echo "  访问：http://127.0.0.1:8787"
