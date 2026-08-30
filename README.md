# CS2 Inventory Simulator - Cloudflare Workers 版

基于 [cs2-inventory-simulator](https://github.com/ianlucas/cs2-inventory-simulator) 移植到 Cloudflare Workers (D1 + KV + Assets) 的全栈版本。

## ✨ 特性

- 🎮 **完整 CS2 库存模拟** - 添加/移除皮肤、贴纸、钥匙扣、补丁、命名标签、StatTrak 交换
- 🔐 **Steam OpenID 登录** - 无密码，安全可靠
- ⚡ **边缘计算** - Cloudflare Workers 全球边缘节点，毫秒级响应
- 💾 **D1 数据库** - SQLite 兼容，自动扩展，按需付费
- 🗂️ **KV 缓存** - 经济数据、投影数据边缘缓存
- 📦 **静态资源** - 内置 Assets 绑定，零配置 CDN
- 🔒 **生产就绪** - HTTPS 自动强制、Secure Cookie、CSP、速率限制

## 🚀 一键部署

### 前置要求

- Node.js 20+
- Cloudflare 账号
- Steam Web API Key ([申请地址](https://steamcommunity.com/dev/apikey))

### 自动部署 (推荐)

```bash
# 1. 克隆仓库
git clone https://github.com/cyqmq/cs2-cfworker-inventory-simulator.git
cd cs2-cfworker-inventory-simulator

# 2. 安装依赖
npm install

# 3. 登录 Cloudflare
wrangler login

# 4. 一键部署 (自动创建 D1、KV、应用迁移、部署 Worker)
./deploy.sh production
```

脚本会自动：
1. ✅ 创建 D1 数据库 `cs2-inventory-production`
2. ✅ 创建 KV 命名空间 `CACHE-production` (含 preview)
3. ✅ 生成 `wrangler.production.jsonc` 绑定真实资源 ID
4. ✅ 远程应用数据库迁移
5. ✅ 提示设置 Secrets (SESSION_SECRET, STEAM_API_KEY, STEAM_CALLBACK_URL)
6. ✅ 构建并部署 Worker

### 手动部署 (分步了解)

<details>
<summary>点击展开手动部署步骤</summary>

```bash
# 1. 创建 D1 数据库
wrangler d1 create cs2-inventory-production
# 记下输出的 database_id

# 2. 创建 KV 命名空间
wrangler kv namespace create CACHE-production
wrangler kv namespace create CACHE-production --preview
# 记下两个 id

# 3. 复制并编辑 wrangler.production.jsonc
cp wrangler.production.jsonc wrangler.jsonc
# 填入 database_id, kv_id, preview_id

# 4. 应用迁移
wrangler d1 migrations apply cs2-inventory-production --remote --yes

# 5. 设置 Secrets (不写入代码/配置文件)
wrangler secret put SESSION_SECRET
wrangler secret put STEAM_API_KEY
wrangler secret put STEAM_CALLBACK_URL

# 6. 构建并部署
npm run build
wrangler deploy
```
</details>

## ⚙️ 配置说明

### 必需 Secrets (在 Cloudflare Dashboard 或 `wrangler secret put`)

| Secret | 说明 | 示例 |
|--------|------|------|
| `SESSION_SECRET` | 会话签名密钥，≥32 字符随机串 | `openssl rand -base64 32` |
| `STEAM_API_KEY` | Steam Web API Key | `__STEAM_API_KEY_PLACEHOLDER__` |
| `STEAM_CALLBACK_URL` | Steam 回调完整 URL (必须 HTTPS) | `https://your-domain.com/sign-in/steam/callback` |

### 环境变量 (wrangler.jsonc vars)

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `NODE_ENV` | 运行环境 | `production` (生产自动强制 HTTPS Cookie) |

### Steam 应用配置

1. 进入 [Steamworks 应用管理](https://partner.steamgames.com/apps/list)
2. 选择你的应用 → **Web API Key** → 设置 **Authorized Domain** 为你的域名
3. **Redirect URI** 设置为 `https://your-domain.com/sign-in/steam/callback`

## 📖 使用教程

### 首次访问初始化

首次访问部署好的 Worker 时，会自动：
1. 初始化数据库表结构 (通过 D1 迁移)
2. 写入 80 条默认 Rule (游戏规则配置)
3. 这可能需要 10-30 秒冷启动时间

### 基本操作

1. **登录**: 点击右上角 "Sign in with Steam"
2. **添加皮肤**: 点击 "+" → 选择皮肤 → 设置磨损/StatTrak/贴纸/钥匙扣/命名标签
3. **编辑皮肤**: 点击皮肤 → "Edit" → 修改属性
4. **移除皮肤**: 点击皮肤 → "Remove"
5. **容器操作**: 添加箱子/胶囊 → 存入/取出皮肤
6. **同步**: 所有操作自动同步到云端 (右上角绿点表示同步中)

### Rule 配置 (运行时逻辑)

无需重新部署即可调整游戏规则，通过 D1 `Rule` 表配置：

```sql
-- 示例：允许所有贴纸操作
INSERT INTO Rule (name, type, value) VALUES ('craftAllowStickers', 'string', 'true');

-- 示例：限制最大贴纸数
INSERT INTO Rule (name, type, value) VALUES ('inventoryItemMaxStickers', 'string', '4');
```

完整 Rule 列表见 [rules.md](docs/rules.md) 或源码 `app/models/rule.ts`。

## 🏗️ 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                     Cloudflare Edge                          │
├─────────────────────────────────────────────────────────────┤
│  Workers (React Router v8 SSR)                               │
│  ├── Assets Binding → 静态资源 (JS/CSS/图片/字体)             │
│  ├── D1 Binding → SQLite 数据库 (用户/库存/Rule/经济数据)      │
│  └── KV Binding → 缓存 (经济价格/投影/速率限制)                │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
            Steam OpenID          客户端浏览器
            认证服务               (React SPA)
```

### 关键技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 框架 | React Router v8 | SSR + SPA 混合，Single Fetch 模式 |
| 运行时 | Cloudflare Workers | V8 Isolates，无冷启动容器 |
| 数据库 | D1 (SQLite) | Prisma ORM + `@prisma/adapter-d1` |
| 缓存 | Workers KV | 经济数据、投影、速率限制桶 |
| 认证 | Steam OpenID 2.0 | Cookie 会话 + HttpOnly Secure |
| 部署 | Wrangler | 零配置 CI/CD |

## 🔧 本地开发

```bash
# 启动本地开发环境 (模拟 D1/KV)
npm run dev

# 访问 http://localhost:8788
# 本地使用 SQLite 文件存储，Steam 回调需配置 frp/ngrok 穿透
```

### 本地环境变量 (.dev.vars)

```bash
# 复制模板
cp .dev.vars.example .dev.vars

# 编辑填入你的值
NODE_ENV=development
SESSION_SECRET=local-dev-secret-change-me
STEAM_API_KEY=your-steam-api-key
STEAM_CALLBACK_URL=http://localhost:8788/sign-in/steam/callback
```

## 📁 项目结构

```
├── app/
│   ├── components/          # React 组件
│   ├── models/              # 业务模型 (Prisma 封装)
│   │   ├── rule.server.ts   # Rule 系统核心
│   │   ├── user.server.ts   # 用户/库存操作 (含 manipulateUserInventory)
│   │   ├── inventory-recovery.server.ts
│   │   └── rate-limit.server.ts
│   ├── routes/              # React Router 路由
│   │   ├── api.action.sync._index.tsx   # 库存同步核心 API
│   │   ├── api.action.preferences._index.tsx
│   │   └── api.sign-in.callback._index.tsx
│   ├── routines/            # 后台定时任务
│   │   ├── economy-price.ts      # 经济价格同步
│   │   └── inventory-projection.ts # 库存投影
│   ├── db.server.ts         # Prisma + D1 适配器
│   ├── session.server.ts    # Cookie 会话存储
│   ├── auth.server.ts       # Steam 认证逻辑
│   └── entry.server.tsx     # SSR 入口
├── workers/
│   └── app.ts               # Workers 入口 (导出 fetch handler)
├── d1-migrations/           # D1 迁移文件
├── wrangler.jsonc           # 本地开发配置
├── wrangler.production.jsonc # 生产环境模板
├── deploy.sh                # 一键部署脚本
└── package.json
```

## 🛠️ 常见问题

### Q: 部署后 Steam 登录报错 "Invalid redirect URI"？
A: 检查 `STEAM_CALLBACK_URL` Secret 是否与 Steam 应用设置的 Redirect URI 完全一致 (含 HTTPS、域名、路径)。

### Q: 登录成功但刷新后未登录？
A: 确认 `NODE_ENV=production` (生产环境自动)，Cookie 会自动加 `Secure`。本地开发需 `NODE_ENV=development`。

### Q: 同步报错 "Cloudflare D1 does not support interactive transactions"？
A: 已在代码中修复 - 所有 `$transaction(async (tx) => {...})` 改为 D1 兼容的批处理事务或顺序执行。

### Q: 如何重置/清空数据库？
```bash
# 删除并重建 D1
wrangler d1 delete cs2-inventory-production
wrangler d1 create cs2-inventory-production
wrangler d1 migrations apply cs2-inventory-production --remote --yes
```

### Q: 如何查看生产日志？
```bash
wrangler tail --format=pretty
# 或 Dashboard > Workers > cs2-inventory-simulator > Logs
```

### Q: 如何绑定自定义域名？
Dashboard > Workers > cs2-inventory-simulator > Triggers > Custom Domains > Add Custom Domain。

## 📊 监控与调试

- **实时日志**: `wrangler tail`
- **指标面板**: Dashboard > Workers > Metrics (请求数、CPU、错误率)
- **D1 查询**: Dashboard > D1 > cs2-inventory-production > Console
- **KV 查看**: Dashboard > Workers KV > CACHE-production

## 💰 成本估算 (Cloudflare 免费额度)

| 资源 | 免费额度 | 超出价格 |
|------|----------|----------|
| Workers 请求 | 100,000/天 | $0.30/百万 |
| Workers CPU | 10ms/请求 | $0.02/百万 CPU 秒 |
| D1 读取 | 500 万行/天 | $0.001/百万行 |
| D1 写入 | 50 万行/天 | $1.00/百万行 |
| D1 存储 | 5 GB | $0.75/GB/月 |
| KV 读取 | 100 万/天 | $0.50/百万 |
| KV 写入 | 1 千/天 | $5.00/百万 |
| Assets | 无限 | 免费 |

**典型个人用量远在免费额度内**。

## 🤝 贡献指南

1. Fork 仓库
2. 创建特性分支: `git checkout -b feat/amazing-feature`
3. 提交变更: `git commit -m 'feat: add amazing feature'`
4. 推送分支: `git push origin feat/amazing-feature`
4. 创建 Pull Request

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE)

## 🙏 致谢

- [Ian Lucas](https://github.com/ianlucas) - 原版 cs2-inventory-simulator 作者
- [Cloudflare](https://cloudflare.com) - Workers/D1/KV 平台
- [Prisma](https://prisma.io) - 类型安全 ORM
- [React Router](https://reactrouter.com) - 全栈 React 框架

---

**部署遇到问题？** 提交 [Issue](https://github.com/cyqmq/cs2-cfworker-inventory-simulator/issues) 或查看 [Discussions](https://github.com/cyqmq/cs2-cfworker-inventory-simulator/discussions)。