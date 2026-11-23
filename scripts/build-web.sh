#!/usr/bin/env bash
# 用法: bash scripts/build-web.sh [stremio-web 的分支或 tag,默认 development]
# 产物: stremio-web/build/ (web 前端静态资源)
set -euo pipefail
cd "$(dirname "$0")/.."

REF="${1:-development}"

echo "==> 克隆 Stremio/stremio-web @ ${REF}"
rm -rf stremio-web
git clone --depth 1 --branch "$REF" https://github.com/Stremio/stremio-web.git
cd stremio-web

echo "==> 安装依赖 (pnpm)"
pnpm install

echo "==> 生产构建 (SERVICE_WORKER_DISABLED=true:嵌入 App 不需要网页 SW 更新机制)"
pnpm exec webpack --mode production --env SERVICE_WORKER_DISABLED=true --no-devtool

echo "==> 构建完成: $(pwd)/build"
ls -la build
