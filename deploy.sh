#!/usr/bin/env bash
# Cloudflare Workers 一键部署脚本
# 用法: ./deploy.sh [production|preview]

set -euo pipefail

ENV="${1:-production}"
echo "🚀 部署到 $ENV 环境..."

# 检查 wrangler 登录
if ! wrangler whoami &>/dev/null; then
    echo "❌ 未登录 Cloudflare，请先运行: wrangler login"
    exit 1
fi

# 1. 创建/获取 D1 数据库
echo "📦 创建 D1 数据库..."
DB_OUTPUT=$(wrangler d1 create "cs2-inventory-$ENV" --json 2>/dev/null || wrangler d1 list --json | jq -r '.[] | select(.name=="cs2-inventory-'$ENV'") | @json')
DB_ID=$(echo "$DB_OUTPUT" | jq -r '.uuid // .id')
DB_NAME=$(echo "$DB_OUTPUT" | jq -r '.name')
echo "   D1: $DB_NAME ($DB_ID)"

# 2. 创建/获取 KV 命名空间
echo "🗂️  创建 KV 命名空间..."
KV_OUTPUT=$(wrangler kv namespace create "CACHE-$ENV" --json 2>/dev/null || wrangler kv namespace list --json | jq -r '.[] | select(.title=="CACHE-'$ENV'") | @json')
KV_ID=$(echo "$KV_OUTPUT" | jq -r '.id')
KV_PREVIEW_OUTPUT=$(wrangler kv namespace create "CACHE-$ENV" --preview --json 2>/dev/null || wrangler kv namespace list --preview --json | jq -r '.[] | select(.title=="CACHE-'$ENV'") | @json')
KV_PREVIEW_ID=$(echo "$KV_PREVIEW_OUTPUT" | jq -r '.id')
echo "   KV (production): $KV_ID"
echo "   KV (preview): $KV_PREVIEW_ID"

# 3. 生成环境特定的 wrangler.jsonc
echo "⚙️  生成 wrangler.$ENV.jsonc..."
cat > "wrangler.$ENV.jsonc" <<EOF
{
  "\$schema": "node_modules/wrangler/config-schema.json",
  "name": "cs2-inventory-simulator",
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
      "database_name": "cs2-inventory-$ENV",
      "database_id": "$DB_ID",
      "migrations_dir": "./d1-migrations"
    }
  ],
  "kv_namespaces": [
    {
      "binding": "CACHE",
      "id": "$KV_ID",
      "preview_id": "$KV_PREVIEW_ID"
    }
  ],
  "vars": {
    "NODE_ENV": "production"
  }
}
EOF

# 4. 应用 D1 迁移
echo "🔄 应用数据库迁移..."
wrangler d1 migrations apply "cs2-inventory-$ENV" --config "wrangler.$ENV.jsonc" --remote --yes

# 5. 提示设置 Secrets
echo ""
echo "🔐 请设置以下 Secrets (在 Cloudflare Dashboard 或运行以下命令):"
echo "   wrangler secret put SESSION_SECRET --config wrangler.$ENV.jsonc"
echo "   wrangler secret put STEAM_API_KEY --config wrangler.$ENV.jsonc"
echo "   wrangler secret put STEAM_CALLBACK_URL --config wrangler.$ENV.jsonc"
echo ""
echo "   SESSION_SECRET: 建议生成随机 32+ 字符"
echo "   STEAM_API_KEY: 你的 Steam Web API Key"
echo "   STEAM_CALLBACK_URL: https://your-domain.com/sign-in/steam/callback"
echo ""

# 6. 构建
echo "🔨 构建项目..."
npm run build

# 7. 部署
echo "📤 部署到 Cloudflare Workers..."
wrangler deploy --config "wrangler.$ENV.jsonc" --env "$ENV"

echo ""
echo "✅ 部署完成！"
echo "   Worker: https://cs2-inventory-simulator.$ENV.your-subdomain.workers.dev"
echo "   或配置自定义域名: Dashboard > Workers > cs2-inventory-simulator > Triggers > Custom Domains"
echo ""
echo "📝 后续步骤:"
echo "   1. 在 Steam 应用管理页设置 Authorized Domain 和 Redirect URI"
echo "   2. 更新 Rule 表的 steamCallbackUrl (或通过 API 设置)"
echo "   3. 首次访问会自动初始化 80 条默认 Rule"