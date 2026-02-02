# 💧 桶装水配送系统

海淀区羊坊店桶装水在线订购 & 管理系统

## 功能

### 📱 客户端（手机友好）
- 商品浏览、加购、下单
- 街道选择 + 详细地址
- 手机号查询历史订单
- 记住用户信息，方便复购

### 🔧 管理后台
- 📊 仪表盘：今日订单/收入/待处理统计
- 📋 订单管理：确认 → 配送 → 完成，全流程操作
- 🧴 库存管理：调价、补货、上下架
- ⚙️ 店铺设置：名称、电话、配送区域、公告
- 🔔 推送通知：新订单手机推送（需配置 VAPID）
- 一键拨打客户电话

## 本地运行

```bash
cd water-delivery
npm install
node server.js
```

- 客户端: http://localhost:3000
- 管理后台: http://localhost:3000/admin
- 默认密码: `water2024`

## 免费部署到 Render

1. 把代码推到 GitHub
2. 去 [render.com](https://render.com) 注册（免费）
3. New → Web Service → 连接你的 GitHub 仓库
4. 设置：
   - **Build Command**: `npm install`
   - **Start Command**: `node server.js`
   - **Plan**: Free
5. 环境变量：
   - `ADMIN_PASS` = 你的管理密码
   - `PORT` = 3000
6. 部署完成后会得到一个 `xxx.onrender.com` 的地址

## 免费部署到 Railway

1. 去 [railway.app](https://railway.app) 注册
2. New Project → Deploy from GitHub
3. 自动检测 Node.js，直接部署
4. 在 Variables 里设置 `ADMIN_PASS`

## Docker 部署

```bash
docker build -t water-delivery .
docker run -p 3000:3000 -e ADMIN_PASS=你的密码 water-delivery
```

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `PORT` | 端口 | 3000 |
| `ADMIN_PASS` | 管理密码 | water2024 |
| `VAPID_PUBLIC` | 推送公钥 | （空=禁用推送） |
| `VAPID_PRIVATE` | 推送私钥 | （空=禁用推送） |

## 开启推送通知

```bash
npx web-push generate-vapid-keys
```

把生成的公钥和私钥分别设置到 `VAPID_PUBLIC` 和 `VAPID_PRIVATE` 环境变量。
然后在管理后台 → 设置 → 点击"开启订单推送通知"。

## 技术栈

- **后端**: Node.js + Express
- **数据库**: SQLite (sql.js，纯 JS 实现)
- **前端**: 原生 HTML/CSS/JS，零依赖
- **推送**: Web Push API
