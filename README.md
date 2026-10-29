# Taste Lab · 审美审查台

> 网页审美提升 —— 把「设计品味」变成可测量、可执行、可交付给 AI 的整改清单。

贴一个网址或传一张图，拿到 **评分 / P0-P2 问题清单 / 可落地 token 建议**，并直接导出一段能粘给 Claude Code、Cursor、OpenClaw 等 AI 编程工具的**中文整改指令**。

全本地运行，数据不出本机。

![评分卡](https://img.shields.io/badge/node-%E2%89%A518.20%20%7C%20playwright-headless-blue) ![许可](https://img.shields.io/badge/license-MIT-green)

---

## 它解决什么问题

AI 生成的页面「看起来对，但说不上好」，人也很难对着截图讲清楚差在哪。这个应用把审美拆成三层：

| 层 | 做什么 | 谁负责 |
|---|---|---|
| **指标层** | 脚本量化：颜色数、字号档数、圆角/阴影/渐变、层级比、WCAG 对比度、中文字体是否用了宋体 | `design-taste` 的 `review_site.py` |
| **视觉层** | 模型看图打分：留白节奏、层级清晰度、签名元素、AI 模板感、动效与无障碍 | MiniMax M3.1 Flash Preview 等视觉模型 |
| **交付层** | 把结论转成带具体数值的整改指令，直接扔给 AI 编程工具执行 | `rubric.md` + `/api/job/<id>/fixpack` |

## 快速开始

```bash
git clone https://github.com/lxy12300ab/tastlab.git
cd tastlab
bash install.sh          # 安装 launchd 常驻并启动
open http://127.0.0.1:8787
```

依赖：Node 18+、Python 3.11+、`pip install playwright && python3 -m playwright install chromium`。

模型密钥不在仓库里 —— 应用运行时从 `~/.openclaw/openclaw.json` 的 `models.providers` 读取；也可以在网页「模型配置」页里添加自定义模型（密钥只存本机 `data/config.json`，已 gitignore）。

## 核心能力

### 模型可切换，双协议自动回退

同一个 provider 常常同时支持两种协议。应用会按优先级依次尝试，任一成功即返回：

| Provider | 端点 | 协议 |
|---|---|---|
| minimax | `https://api.minimaxi.com/v1/chat/completions` | OpenAI 兼容（支持带图） |
| minimax | `https://api.minimaxi.com/anthropic/v1/messages` | Anthropic 协议（支持带图） |
| deepseek | `https://api.deepseek.com/chat/completions` | OpenAI 兼容 |

默认 `minimax/MiniMax-M3.1-Flash-Preview`。「模型配置」页可切换默认模型、测连通性、添加自定义模型。

### 行业对标基准（中文下拉）

下拉显示中文，接口传英文 key（对齐 `skills/design-taste/scripts/benchmarks.csv`）：

| 显示 | 接口取值 | 显示 | 接口取值 |
|---|---|---|---|
| 软件 / SaaS / 云服务 | `Software/Cloud` | 金融 / 银行 / 保险 | `Finance` |
| 互联网平台 | `Internet` | 制药 | `Pharma` |
| 半导体 | `Semiconductors` | 医疗健康 | `Healthcare` |
| 硬件 / 消费电子 | `Hardware/Devices` | 零售 / 电商 | `Retail` |
| 工业制造 | `Industrial` | 快消 / 日用消费品 | `Consumer Goods` |
| 汽车 / 电池 | `Auto/Battery` | 奢侈品 / 高端零售 | `Luxury` |
| 能源 / 电力 | `Energy` | 航空航天 / 国防 | `Aerospace` |
| 矿业 | `Mining` | 传媒 / 内容 | `Media` |
| 综合集团 | `Conglomerate` | 汽车 | `Auto` |

选行业后，评审提示里会带上该行业的**平均分与标杆站点**，模型据此判断差距。

### 后台应用：登录态

管理后台、内部控制台这类应用直接发网址只会停在登录页，采到的指标和截图都不代表真实界面。

1. 填网址 → 点「登录并保存会话」
2. 弹出可见浏览器窗口，人工登录一次
3. 脚本检测到登录成功后自动保存 `data/auth/<host>.json`
4. 之后审查该站自动带上登录态（`--storage-state`）

采集阶段还会检测 `loginWall`（可见密码框 / 登录词 + 短正文），命中时前端顶部出橙色横幅，并明确告诉模型「别把登录表单当设计缺陷」。

### 对标参考：学习对方优秀的设计来修当前页面

在审查表单里展开「对标参考」，可以给出：参考网址、上传的参考截图、以及你想学的具体规则（如「学它的首屏留白节奏」）。

工具按三阶段跑，**关键是先抽象再借鉴**：

1. **采集参考对象** —— 网址走 Playwright 采集截图与指标；上传的截图直接用
2. **单独提炼手法** —— 另起一次模型调用，把参考对象拆成「可迁移的设计手法」（原理 + 证据 + 迁移做法），而不是记它的色值和字号
3. **注入主评审** —— 主评审同时看到我们的页面、参考页面截图、以及提炼出的手法，产出借鉴建议

第 2 步是刻意的：如果把参考页面直接丢给主评审，模型会照抄色值和字号；先抽象成手法再注入，学到的才是排版逻辑与层级策略。

结果页的「对标借鉴」板块会列出参考对象值得学的手法、签名元素、不该照搬的地方，以及「我们缺什么 → 具体怎么改」（带参数）。整改指令包里也会多出一节「对标借鉴」，让 AI 改代码时同时看到「学什么」和「怎么改」。

### 中文网页不该用宋体

中文网页正文用宋体、仿宋、楷体是印刷品遗留的过时做法。脚本统计**中文字形实际落到衬线**的比例：

- 占比 ≥ 50% → 字体分额外 **−10**
- 占比 ≥ 20% → 字体分额外 **−5**
- 占比 ≥ 15% → 字体分额外 **−3**

判定依据不是 CSS 声明的第一个字族，而是整条字体栈能否给中文提供黑体。因为中文网页常写 `font-family: "Optima", Georgia, serif` —— 拉丁走 Optima，而**中文字形静默回退到系统宋体/明朝体**，只看第一个字族会完全漏报。

并在评审提示与报告里点名，要求改用黑体族（思源黑体 / 苹方 / 微软雅黑）。`tokens.font_family` 也不会再给宋体。

### 整改指令包（给 AI 改代码）

结果页点「复制整改指令（给 AI 改代码）」，产出可直接粘给 AI 编程工具的中文 Markdown：

- 审查结论
- 客观指标清单（必须全达标）
- 设计 token CSS 块（直接覆盖）
- 逐条整改任务（按 P0→P2 排，含「现状 / 改法 / 验收」）
- 硬性约束（不引新框架、颜色 ≤12、字号 ≤7、中文不用宋体…）
- 下一步动作

也可下载 `.md`。

## API

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/api/review/site` | `{url, industry?, mobile?, model?, reference?: {url?, notes?, images?}}` → `{id}` |
| POST | `/api/review/image` | `{dataUrl, filename?, type?, model?}` → `{id}` |
| GET | `/api/job/<id>` | job 状态与结果 |
| GET | `/api/job/<id>/fixpack` | 整改指令包（Markdown） |
| GET | `/api/models` | 可选模型列表 + 能力标记 |
| GET | `/api/industries` | 行业列表（中文 label + 英文 value） |
| GET / POST | `/api/config` | 读取 / 保存默认模型 |
| POST | `/api/config/custom-model` | 添加自定义模型 |
| DELETE | `/api/config/custom-model/<id>` | 删除自定义模型 |
| POST | `/api/config/test-model` | 测试模型连通性 |
| GET | `/api/auth-state?url=` | 是否已有登录态 |
| POST | `/api/auth/login` | 拉起可见浏览器登录 |
| GET | `/runs/<jobId>/<file>` | 截图 |
| GET | `/api/health` | 健康检查 |

## 目录结构

```
apps/taste-lab/
  server.mjs          Node 原生 http，无第三方依赖
  rubric.md           评审准则（评分公式、阈值、视觉维度、问题分级）
  web/                前端（index.html + style.css，无构建）
  scripts/login.py    交互式登录脚本（保存后台应用登录态）
  data/               本地配置与登录态（gitignore）
  runs/<jobId>/       每次审查的截图、指标、job.json
skills/
  design-taste/       采集与评审脚本 + 基准库（MIT，来自 clawhub）
  taste-lab/          供 agent 调用的 skill 封装
launchd/              launchd 常驻模板
```

## 运维

服务由 launchd 常驻（`com.local.appdesk-taste-lab`），不挂在网关进程下，不会被会话回收带走。

```bash
launchctl list | grep taste-lab
launchctl kickstart -k gui/$(id -u)/com.local.appdesk-taste-lab   # 重启
tail -f /tmp/appdesk-taste-lab.err.log
```

## 已知限制

- 遇到 403 / 验证码的站点不绕过反爬，改用图片模式。
- 分数是代理指标，不是审美真理；视觉分占 55%（图片模式 40%）。
- 登录态是 Playwright `storage_state`，站点若强制短周期会话需重新登录。
- 行业基准库 147 条，样本少的行业均值波动大。
- 服务重启时正在跑的审查会中断，15 分钟后该任务收敛为 error 并提示重新发起。

## 致谢

- [`design-taste`](https://clawhub.ai) skill（MIT，publisher: [linkxzhou](https://clawhub.ai/user/linkxzhou)）—— 采集脚本、评审准则与行业基准库，随仓库分发以保证可独立运行。
- `Impeccable` —— 框架层评审维度（排版、色彩、动效、无障碍、反 AI 模板感）的来源。

## License

MIT，见 [LICENSE](LICENSE)。
