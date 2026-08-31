#!/usr/bin/env bash
# Cloudflare Workers 本地一键部署脚本（与 CI 共用同一生产 worker）
# 依赖：npm install、wrangler login（或 CLOUDFLARE_API_TOKEN 环境变量）
# 用法: ./deploy.sh [preview|production]  默认 preview

set -euo pipefail

ENV="${1:-preview}"
DOMAIN="clc.ccwu.cc"
SCRIPT="cs2-cfworker-inventory-simulator"
D1_NAME=$(node -p "require('./package.json').cloudflare.d1.database_name")
D1_ID=$(node -p "require('./package.json').cloudflare.d1.id")
KV_ID=$(node -p "require('./package.json').cloudflare.kv.id")

echo "🚀 部署 $ENV 环境 → $SCRIPT"

# 检查 wrangler 登录
if ! wrangler whoami &>/dev/null; then
    echo "❌ 未登录 Cloudflare，请先运行: wrangler login"
    exit 1
fi

# 生成 wrangler.jsonc（内容与 deploy.yml 保持一致）
cat > wrangler.jsonc <<EOF
{
  "\$schema": "node_modules/wrangler/config-schema.json",
  "name": "$SCRIPT",
  "main": "./workers/app.ts",
  "compatibility_date": "2025-08-01",
  "compatibility_flags": ["nodejs_compat"],
  "assets": {
    "directory": "./build/client",
    "binding": "ASSETS"
  },
  "observability": {
    "enabled": true
  },
  "d1_databases": [
    {
      "binding": "DB",
      "database_name": "$D1_NAME",
      "database_id": "$D1_ID",
      "migrations_dir": "./d1-migrations"
    }
  ],
  "kv_namespaces": [
    {
      "binding": "CACHE",
      "id": "$KV_ID"
    }
  ],
  "vars": {
    "NODE_ENV": "production"
  },
  "routes": [
    { "pattern": "$DOMAIN", "custom_domain": true }
  ]
}
EOF

# 应用 D1 迁移
echo "🔄 应用数据库迁移..."
wrangler d1 migrations apply "$D1_NAME" --config wrangler.jsonc --remote --yes

# 设置 Secrets（⚠️ 必须在 wrangler deploy 之前完成！否则会丢失绑定）
echo "🔐 设置 Secrets（从环境变量读取，请先 export）..."
set_secret() {
    local name="$1" value="${!1:-}"
    if [ -n "$value" ]; then
        echo "$value" | wrangler secret put "$name" --name "$SCRIPT"
    else
        echo "  跳过 $name（环境变量未设置）"
    fi
}
set_secret SESSION_SECRET
set_secret STEAM_API_KEY
set_secret STEAM_CALLBACK_URL

# 构建
echo "🔨 构建项目..."
npm run build

# 部署
echo "📤 部署到 Cloudflare Workers..."
wrangler deploy --config wrangler.jsonc

echo ""
echo "✅ 部署完成！访问: https://$DOMAIN"
echo "   请注意：若 RULE 表已存在 steamCallbackUrl，仍以 D1 值为准（需要时 UPDATE D1）"
