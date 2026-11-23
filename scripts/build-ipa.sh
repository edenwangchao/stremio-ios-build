#!/usr/bin/env bash
# 组装未签名 IPA:编译 iOS 壳(arm64, deployment target 15.0)+ 打包 web 构建产物
# 前置: 已先运行 scripts/build-web.sh
set -euo pipefail
cd "$(dirname "$0")/.."

WEB_DIR="stremio-web/build"
if [ ! -d "$WEB_DIR" ]; then
    echo "缺少 web 构建产物 ($WEB_DIR),请先运行: bash scripts/build-web.sh" >&2
    exit 1
fi

APP_NAME="Stremio.app"
rm -rf build
mkdir -p "build/Payload/$APP_NAME"
APP="build/Payload/$APP_NAME"

cp shell/Info.plist "$APP/Info.plist"
cp shell/icons/AppIcon60x60@2x.png "$APP/AppIcon60x60@2x.png"
cp -R "$WEB_DIR" "$APP/web"

echo "==> 编译 iOS 壳 (swiftc, arm64-apple-ios15.0)"
xcrun -sdk iphoneos swiftc -O -parse-as-library \
    -target arm64-apple-ios15.0 \
    shell/SchemeHandler.swift shell/AppDelegate.swift \
    -o "$APP/Stremio"

echo "==> 打包未签名 IPA"
( cd build && zip -qyr Stremio-web-iOS15-unsigned.ipa Payload )
ls -lh build/Stremio-web-iOS15-unsigned.ipa
echo "==> 完成: build/Stremio-web-iOS15-unsigned.ipa (未签名,请用 Sideloadly/AltStore 等自签)"
