# CS2 Inventory Simulator - Cloudflare Workers 版

> ✅ 已突破 Cloudflare 免费版 3MB 限制：Worker 产物 gzip 压缩后 **≈2.99 MB**（低于 3,072 KB 免费上限），已可在免费套餐上正常构建与部署。

基于 [cs2-inventory-simulator](https://github.com/ianlucas/cs2-inventory-simulator) 移植到 Cloudflare Workers (D1 + KV + Assets) 的全栈版本。

[![Deploy to Cloudflare Workers](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?repository-url=https://github.com/cyqmq/cs2-cfworker-inventory-simulator)

**点击上方按钮 → 授权 GitHub → 自动创建 D1/KV → 部署完成** (约 2-3 分钟)

> ⚠️ 使用下方「方式 2 / 方式 3」时，务必先在仓库配置 `CLOUDFLARE_API_TOKEN` 和 `CLOUDFLARE_ACCOUNT_ID` 两个 Secrets，否则 GitHub Actions 无法通过 Cloudflare 认证，**自动创建/绑定 D1 与 KV 的流程不会执行**（详见「🔑 必读：自动创建 D1/KV 的前提」）。

## ✨ 特性

- 🎮 **完整 CS2 库存模拟** - 添加/移除皮肤、贴纸、钥匙扣、补丁、命名标签、StatTrak 交换
- 🔐 **Steam OpenID 登录** - 无密码，安全可靠
- ⚡ **边缘计算** - Cloudflare Workers 全球边缘节点，毫秒级响应
- 💾 **D1 数据库** - SQLite 兼容，自动扩展，按需付费
- 🗂️ **KV 缓存** - 经济数据、投影数据边缘缓存
- 📦 **静态资源** - 内置 Assets 绑定，零配置 CDN
- 🔒 **生产就绪** - HTTPS 自动强制、Secure Cookie、CSP、速率限制

## 🚀 一键部署

### 方式 1：点击部署按钮 (最简单，无需本地环境)

[![Deploy to Cloudflare Workers](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?repository-url=https://github.com/cyqmq/cs2-cfworker-inventory-simulator)

**流程**：
1. Fork 本仓库到你的 GitHub 账号
2. 点击上方按钮 → 授权 GitHub → 触发 **GitHub Actions 部署**（Deploy Button 与"方式 2"走同一条 `deploy.yml` 流水线）
3. 部署流水线自动：
   - ✅ 解析并绑定 D1 数据库（默认 `cs2-inventory-db`）与 KV 命名空间（默认 `cs2-inventory-kv`）
   - ✅ 运行数据库迁移（`wrangler d1 migrations apply --remote`）
   - ✅ 在 `wrangler deploy` **之前**通过 API 设置 Secrets
   - ✅ 构建并部署 Worker，并将 `clc.ccwu.cc` 绑定为 custom domain
   - ✅ 部署后校验 active deployment 含完整绑定（D1+KV+ASSETS+Secrets）
4. 部署前需在 Fork 仓库 **Settings > Secrets and variables > Actions** 添加：
   - `CLOUDFLARE_API_TOKEN`、`CLOUDFLARE_ACCOUNT_ID`
   - `SESSION_SECRET` (随机 32+ 字符，`openssl rand -base64 32`)
   - `STEAM_API_KEY`、`STEAM_CALLBACK_URL`（`https://your-domain.com/sign-in/steam/callback`）
5. 在 Steam 应用管理页设置 Redirect URI 为 `https://your-domain.com/sign-in/steam/callback`

> ⚠️ 部署流水线的 Secrets 会写入 Cloudflare 侧，**无需**再到 Dashboard 手动添加。

### 方式 2：Fork 后 GitHub Actions 自动部署 (推荐生产)

与「方式 1」共用同一个 `deploy.yml`。流程：
1. **Fork 本仓库** 到你的 GitHub
2. 在 Fork 的仓库 **Settings > Secrets and variables > Actions** 添加：
   ```
   CLOUDFLARE_API_TOKEN     # Cloudflare API Token (编辑 Workers 权限)
   CLOUDFLARE_ACCOUNT_ID    # 你的 Cloudflare Account ID
   SESSION_SECRET           # 随机 32+ 字符
   STEAM_API_KEY            # Steam Web API Key
   STEAM_CALLBACK_URL       # https://your-domain.com/sign-in/steam/callback
   ```
3. 推送到 `main` 分支 → Actions 自动部署
4. 部署后访问 `https://clc.ccwu.cc`（如需换域名，修改 `deploy.yml` 的 custom domain 并更新 `STEAM_CALLBACK_URL` / D1 `steamCallbackUrl` Rule）

### 🔑 必读：D1/KV 绑定与 Secrets

`deploy.yml` 通过 **环境变量 / Secrets / workflow_dispatch 输入** 把 D1 与 KV 的 ID 注入 `wrangler.jsonc` 绑定配置，然后执行 `wrangler deploy`。

1. `workflow_dispatch` 手动触发时，在「Run workflow」界面填入 `d1_database_id` 和 `kv_namespace_id`（可用现有资源的 ID）
2. 或在仓库 Secrets 配置 `D1_DATABASE_ID` / `KV_NAMESPACE_ID`（推荐，自动生效）
3. 都不填时，使用 `package.json` 中 `cloudflare` 配置的默认 ID（`d1.id` / `kv.id`，即当前 `cs2-inventory-db` / `cs2-inventory-kv`）生成带完整绑定的 `wrangler.jsonc`，应用 D1 迁移并部署 Worker

**ID 优先级**：工作流输入 > Secrets (`D1_DATABASE_ID` / `KV_NAMESPACE_ID`) > `package.json` 默认值。

请确保以下 Secrets 已配置（用于 Cloudflare 认证 + 可选覆盖资源）：
- `CLOUDFLARE_API_TOKEN` —— Cloudflare API Token（需有 `Workers Scripts: Edit`、`D1: Edit`、`Workers KV Storage: Edit` 权限）
- `CLOUDFLARE_ACCOUNT_ID` —— 你的 Cloudflare 账号 ID（Dashboard 右下角可查）
- `D1_DATABASE_ID` *(可选)* —— 现有 D1 数据库 ID，默认取 `package.json` `cloudflare.d1.id`（当前 `cs2-inventory-db`）
- `KV_NAMESPACE_ID` *(可选)* —— 现有 KV 命名空间 ID，默认取 `package.json` `cloudflare.kv.id`（当前 `cs2-inventory-kv`）

如果 `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID` **没有配置**（或为空），GitHub Actions 会卡在认证步骤，`whoami` 显示 `You are not authenticated`，**部署命令未认证而失败**，Worker 即使部署成功也没有 D1/KV 绑定——表现就是「部署成功但没有绑定」。

运行 `npm run deploy:info` 可随时查看当前绑定的 D1/KV 名称与 ID，以及如何获取现有资源 ID。

**配置后**，重新触发部署（重新 push 到 `main` 或手动 Re-run），即可用现有 D1 + KV 绑定并部署。

> ⚠️ **不要在 `wrangler deploy` 之后单独执行 `wrangler secret put`！** 这会创建一个仅含 secret、丢失全部绑定（D1/KV/Assets）的新版本并成为 active，导致 404。Secrets 应在 `wrangler deploy` **之前**通过 API 或 deploy.yml 流水线写入。

### 方式 3：本地 CLI 部署 (开发调试)

```bash
git clone https://github.com/cyqmq/cs2-cfworker-inventory-simulator.git
cd cs2-cfworker-inventory-simulator
npm install
wrangler login
# 先 export 三个 Secret（deploy.sh 会在构建/部署前设置，避免丢失绑定）
export SESSION_SECRET="$(openssl rand -base64 32)"
export STEAM_API_KEY="你的 Steam Web API Key"
export STEAM_CALLBACK_URL="https://clc.ccwu.cc/sign-in/steam/callback"
./deploy.sh production
```

脚本生成 `wrangler.jsonc`（与 CI 同一个 worker `cs2-cfworker-inventory-simulator`）、应用迁移、设置 Secrets、构建并部署到 `clc.ccwu.cc`。

### 手动部署 (分步了解)

<details>
<summary>点击展开手动部署步骤</summary>

```bash
# 1. 创建 D1 数据库
wrangler d1 create cs2-inventory-db
# 记下输出的 database_id

# 2. 创建 KV 命名空间
wrangler kv namespace create cs2-inventory-kv
wrangler kv namespace create cs2-inventory-kv --preview
# 记下两个 id

# 3. 复制并编辑 wrangler.jsonc（填入 database_id, kv_id, preview_id）
# 注意：wrangler.jsonc 已在 .gitignore 中，不会提交到仓库

# 4. 应用迁移
wrangler d1 migrations apply cs2-inventory-db --remote --yes

# 5. 设置 Secrets（⚠️ 必须在 wrangler deploy 之前完成！）
#    单独的 wrangler secret put 会创建仅含 secret 的空绑定版本导致 404
#    推荐使用 deploy.yml 流水线（自动处理顺序），或通过 API 批量写入
wrangler secret put SESSION_SECRET
wrangler secret put STEAM_API_KEY
wrangler secret put STEAM_CALLBACK_URL

# 6. 构建并部署（此时绑定已完整）
npm run build
wrangler deploy

# 7. 部署后校验（可选）：确认 active deployment 含完整绑定
curl -s "https://api.cloudflare.com/client/v4/accounts/{account_id}/workers/deployments" \
  --header "Authorization: Bearer {api_token}" \
  --data-urlencode "script_name=cs2-cfworker-inventory-simulator" | jq
```
</details>

## ⚙️ 配置说明

### 必需 Secrets (由 deploy.yml 在部署时写入 Cloudflare)

| Secret | 说明 | 示例 |
|--------|------|------|
| `SESSION_SECRET` | 会话签名密钥，≥32 字符随机串 | `openssl rand -base64 32` |
| `STEAM_API_KEY` | Steam Web API Key（最终生效值也存 D1 `Rule.steamApiKey`） | `你的 Steam Web API Key` |
| `STEAM_CALLBACK_URL` | Steam 回调完整 URL (必须 HTTPS)（最终生效值也存 D1 `Rule.steamCallbackUrl`） | `https://your-domain.com/sign-in/steam/callback` |

> 注意：`STEAM_API_KEY` / `STEAM_CALLBACK_URL` 的**实际生效值由 D1 `Rule` 表决定**（存在时优先于 Secret）。需要改时同步更新 D1。

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

最常改的两个运行配置也持久化在 D1 `Rule` 表（非 KV）：

- `steamApiKey` —— Steam Web API Key
- `steamCallbackUrl` —— Steam 回调地址（如 `https://clc.ccwu.cc/sign-in/steam/callback`）

> ⚠️ Rule 表的值**优先于** env/Secret 默认值（`register()` 仅在无记录时写入 defaultValue）。所以改了 env/Secret 后如需生效，须同步 UPDATE D1 中对应的 Rule。

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
├── wrangler.jsonc           # 本地开发配置（gitignore，CI 动态生成）
├── deploy.sh                # 本地一键部署脚本（与 CI 共用同一 worker）
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
wrangler d1 delete cs2-inventory-db
wrangler d1 create cs2-inventory-db
wrangler d1 migrations apply cs2-inventory-db --remote --yes
```

### Q: 如何查看生产日志？
```bash
wrangler tail --format=pretty
# 或 Dashboard > Workers > cs2-cfworker-inventory-simulator > Logs
```

### Q: 如何绑定自定义域名？
Dashboard > Workers > cs2-cfworker-inventory-simulator > Triggers > Custom Domains > Add Custom Domain（本仓库为 `clc.ccwu.cc`，已在 `deploy.yml` 中通过 `routes` 的 `custom_domain` 自动绑定）。

### Q: 登录时提示 "登录到 localhost"？
应用回调地址（`steamCallbackUrl`）持久化在 D1 的 `Rule` 表中。若之前用 localhost 登录过，D1 中可能残留旧值。修正方式（任选其一）：
- 直接 UPDATE D1：`UPDATE Rule SET value='https://clc.ccwu.cc/sign-in/steam/callback' WHERE name='steamCallbackUrl'`
- 删除该记录让应用重新读取 env 默认值：`DELETE FROM Rule WHERE name='steamCallbackUrl'`

> Steam 登录重定向验证：`curl -sI https://clc.ccwu.cc/sign-in | grep -i location` 应看到 `openid.return_to=https%3A%2F%2Fclc.ccwu.cc%2Fsign-in%2Fsteam%2Fcallback`。

### ⚠️ 部署避坑（CI 实测结论）

以下为在真实 CI 中踩过的坑，按 `deploy.yml` / `ci.yml` 修复要点整理：

1. **CI 里不要用裸 `wrangler`**。wrangler 不是本仓库的 `devDependencies`，而是 `@cloudflare/vite-plugin` 的传递依赖；除非全局安装，否则裸 `wrangler`（migrate / secret bulk / deploy）可能 `exit 127` 找不到命令。CI 中统一用 **`npx wrangler`**。

2. **`wrangler secret bulk` 期望 JSON 对象** `{"KEY": "value"}`，**不是**数组 `[{"name","text"}]`。写成数组会报 `The value for "0" ... is of type "object"`。用 Python `json.dump({k:v ...})` 生成对象。

3. **Secrets 必须在 `wrangler deploy` 之前写入**，且不要事后单独 `wrangler secret put`（会生成仅含 secret、丢失 D1/KV/Assets 绑定的新版本导致 404）。

4. **`skipDuplicates: true` 在 D1 不可用**（该连接器类型标为 `never`）。需要幂等插入时改用 `upsert`（含主键）或先经 `lastSucceededSourceDate` 等短路。

5. **equipped / inventory API 依赖 `CS2Economy` 加载**。`CS2Economy.load` 原仅在页面渲染路径执行，API 冷 isolate 未初始化会导致 equipped 接口稳定返回空。已通过 `app/utils/economy-init.server.ts` 的幂等 `ensureEconomyLoaded()` 在 `entry.server.tsx` 与 `api.server.ts` 处理器中统一调用。

6. **CI 的 `npm ci` 需 `--legacy-peer-deps`**：`@react-router/cloudflare` 与 `@cloudflare/workers-types` 有 peer 冲突，不加会 `ERESOLVE` 失败。

7. **vitest 下要跳过 Cloudflare vite 插件**：`cloudflare()` 在 `VITEST` 环境会因 `resolve.external` 报错；用 `!process.env.VITEST && cloudflare(...)` 条件化（与 `reactRouter()` 处理一致）。


- **实时日志**: `wrangler tail`
- **指标面板**: Dashboard > Workers > Metrics (请求数、CPU、错误率)
- **D1 查询**: Dashboard > D1 > cs2-inventory-db > Console
- **KV 查看**: Dashboard > Workers KV > cs2-inventory-kv

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

