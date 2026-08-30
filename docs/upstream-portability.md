# 上游更新后可移植性分析

> 目标：cs2-inventory-simulator（上游 GitHub）发布新版后，如何做到在 Cloudflare 版（D1+KV）上"直接改造"。

## 结论

**基本可行，但非 100% 无脑覆盖。** 能做到"绝大多数更新直接可用，少数基础设施文件需手动合并"。

可移植性取决于**冲突面**：冲突只发生在上游改动的文件与本地改过的同一文件之间。

## 关键：冲突面 = 上游更改频率 × 本地侵入深度

### 两类文件的命运

| 类型 | 例子 | 上游更新时 |
|---|---|---|
| 纯增量（绝大多数） | 新路由、新组件、新 model、`schema.prisma` 加表 | ✅ 直接覆盖即可，零冲突 |
| 适配层（本地锁死） | `db.server.ts`、`entry.server.tsx`、`env.server.ts`、`rate-limit.server.ts` | ⚠️ 上游一改就冲突，需手动处理 |

## 三个结构性差异点（无法避免，根源是运行时不同）

| # | 文件 | Node 现状 | Cloudflare 需改为 | 冲突风险 |
|---|---|---|---|---|
| 1 | `app/entry.server.tsx` | `renderToPipeableStream` + `PassThrough` | `renderToReadableStream`（Web API） | 高：上游改渲染必冲突 |
| 2 | `app/env.server.ts` | 模块加载时 `dotenv` 读 `process.env` | 异步从 Worker `env` 绑定注入，无 `process.env` | 最高：注入模型根本不同 |
| 3 | `app/db.server.ts` | `PrismaPg` + 连接池 | `PrismaD1`，无连接池概念 | 高：连接方式根本不同 |

## 设计原则（把冲突压到最小）

1. 把 entry/env/db 等适配文件标记为**本地区域，不随上游覆盖**（git 里锁死）。
2. 其余业务文件（路由/model/data）**跟随上游自动覆盖/拷贝**。
3. 冲突用 `git merge`（而非覆盖），让 git 帮助 diff 而非整体覆盖。
4. 新增功能如果能做在上游文件之外（独立 adapter 层），尽量隔离。

## 现实预期

- 非适配层（估计 80-90% 代码）：上游更新 → **直接覆盖可自动**。
- 适配层（entry/env/db 等少数文件）：上游每次动这些 → **需人工处理**。
- 若上游极少改这些基础设施文件，实际体验 ≈ "基本直接改造"。

> 注：无法做到 100% 无脑覆盖的根因是 Cloudflare Worker 与 Node 的运行时差异（流式渲染 API、无 `process.env`、无 `PrismaPg`），这不是配置能绕开的，是不可兼得的取舍。
