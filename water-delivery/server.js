const express = require('express');
const cors = require('cors');
const path = require('path');
const { getDB } = require('./database');
const webpush = require('web-push');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ============ Web Push 配置 ============
const VAPID_PUBLIC = process.env.VAPID_PUBLIC || '';
const VAPID_PRIVATE = process.env.VAPID_PRIVATE || '';

if (VAPID_PUBLIC && VAPID_PRIVATE) {
  webpush.setVapidDetails('mailto:water@example.com', VAPID_PUBLIC, VAPID_PRIVATE);
}

async function notifyAdmin(title, body) {
  if (!VAPID_PUBLIC) return;
  const db = await getDB();
  const subs = db.prepare('SELECT * FROM push_subscriptions').all();
  for (const sub of subs) {
    try {
      await webpush.sendNotification(
        { endpoint: sub.endpoint, keys: { p256dh: sub.keys_p256dh, auth: sub.keys_auth } },
        JSON.stringify({ title, body })
      );
    } catch (err) {
      if (err.statusCode === 410) {
        db.prepare('DELETE FROM push_subscriptions WHERE id = ?').run(sub.id);
      }
    }
  }
}

// ============ 生成订单号 ============
function generateOrderNo() {
  const now = new Date();
  const date = now.toISOString().slice(0, 10).replace(/-/g, '');
  const rand = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  return `WD${date}${rand}`;
}

// ============ 客户端 API ============

app.get('/api/products', async (req, res) => {
  const db = await getDB();
  const products = db.prepare('SELECT * FROM products WHERE active = 1').all();
  res.json({ success: true, data: products });
});

app.get('/api/settings', async (req, res) => {
  const db = await getDB();
  const rows = db.prepare('SELECT * FROM settings').all();
  const settings = {};
  rows.forEach(r => settings[r.key] = r.value);
  res.json({ success: true, data: settings });
});

app.get('/api/push/vapid-key', (req, res) => {
  res.json({ success: true, key: VAPID_PUBLIC });
});

app.post('/api/push/subscribe', async (req, res) => {
  const { endpoint, keys } = req.body;
  if (!endpoint) return res.status(400).json({ success: false, message: '无效的订阅信息' });
  try {
    const db = await getDB();
    db.prepare('INSERT OR REPLACE INTO push_subscriptions (endpoint, keys_p256dh, keys_auth) VALUES (?, ?, ?)')
      .run(endpoint, keys?.p256dh || '', keys?.auth || '');
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

app.post('/api/orders', async (req, res) => {
  const { customer_name, phone, address, street, note, items } = req.body;

  if (!customer_name || !phone || !address || !street || !items?.length) {
    return res.status(400).json({ success: false, message: '请填写完整信息' });
  }
  if (!/^1[3-9]\d{9}$/.test(phone)) {
    return res.status(400).json({ success: false, message: '手机号格式不正确' });
  }

  const db = await getDB();
  const order_no = generateOrderNo();

  let total_price = 0;
  const productDetails = [];
  for (const item of items) {
    const product = db.prepare('SELECT * FROM products WHERE id = ? AND active = 1').get(item.product_id);
    if (!product) return res.status(400).json({ success: false, message: '商品不存在' });
    if (product.stock < item.quantity) {
      return res.status(400).json({ success: false, message: `${product.name} 库存不足` });
    }
    total_price += product.price * item.quantity;
    productDetails.push({ ...product, quantity: item.quantity });
  }

  const doOrder = db.transaction(() => {
    const result = db.prepare(
      'INSERT INTO orders (order_no, customer_name, phone, address, street, note, total_price) VALUES (?, ?, ?, ?, ?, ?, ?)'
    ).run(order_no, customer_name, phone, address, street, note || '', total_price);

    const orderId = result.lastInsertRowid;
    for (const item of productDetails) {
      db.prepare('INSERT INTO order_items (order_id, product_id, product_name, price, quantity) VALUES (?, ?, ?, ?, ?)')
        .run(orderId, item.id, item.name, item.price, item.quantity);
      db.prepare('UPDATE products SET stock = stock - ? WHERE id = ?')
        .run(item.quantity, item.id);
    }
    return orderId;
  });

  try {
    const orderId = doOrder();
    const itemDesc = productDetails.map(p => `${p.name}×${p.quantity}`).join(', ');
    notifyAdmin('🔔 新订单', `${customer_name} ${street} ${itemDesc} ¥${total_price}`);

    res.json({
      success: true,
      data: { id: orderId, order_no, total_price },
      message: '下单成功！我们将尽快配送'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: '下单失败，请重试' });
  }
});

app.get('/api/orders/query', async (req, res) => {
  const { phone } = req.query;
  if (!phone) return res.status(400).json({ success: false, message: '请输入手机号' });
  const db = await getDB();
  const orders = db.prepare(`
    SELECT o.*, GROUP_CONCAT(oi.product_name || '×' || oi.quantity, ', ') as items_desc
    FROM orders o
    LEFT JOIN order_items oi ON o.id = oi.order_id
    WHERE o.phone = ?
    GROUP BY o.id
    ORDER BY o.created_at DESC
    LIMIT 20
  `).all(phone);
  res.json({ success: true, data: orders });
});

// ============ 管理后台 API ============
const ADMIN_PASS = process.env.ADMIN_PASS || 'water2024';

function adminAuth(req, res, next) {
  const token = req.headers['x-admin-token'];
  if (token !== ADMIN_PASS) {
    return res.status(401).json({ success: false, message: '未授权' });
  }
  next();
}

app.post('/api/admin/login', (req, res) => {
  const { password } = req.body;
  if (password === ADMIN_PASS) {
    res.json({ success: true, token: ADMIN_PASS });
  } else {
    res.status(401).json({ success: false, message: '密码错误' });
  }
});

app.get('/api/admin/orders', adminAuth, async (req, res) => {
  const { status, date, page = 1, limit = 20 } = req.query;
  const db = await getDB();

  let sql = `
    SELECT o.*, GROUP_CONCAT(oi.product_name || '×' || oi.quantity, ', ') as items_desc
    FROM orders o
    LEFT JOIN order_items oi ON o.id = oi.order_id
  `;
  const params = [];
  const conditions = [];

  if (status && status !== 'all') { conditions.push('o.status = ?'); params.push(status); }
  if (date) { conditions.push("DATE(o.created_at) = ?"); params.push(date); }
  if (conditions.length) sql += ' WHERE ' + conditions.join(' AND ');

  sql += ' GROUP BY o.id ORDER BY o.created_at DESC';
  sql += ` LIMIT ? OFFSET ?`;
  params.push(Number(limit), (Number(page) - 1) * Number(limit));

  const orders = db.prepare(sql).all(...params);

  let countSql = 'SELECT COUNT(DISTINCT o.id) as total FROM orders o';
  const countParams = [];
  if (conditions.length) {
    countSql += ' WHERE ' + conditions.join(' AND ');
    countParams.push(...params.slice(0, conditions.length));
  }
  const countResult = db.prepare(countSql).get(...countParams);

  res.json({ success: true, data: orders, total: countResult?.total || 0, page: Number(page), limit: Number(limit) });
});

app.put('/api/admin/orders/:id/status', adminAuth, async (req, res) => {
  const { status, payment_status } = req.body;
  const db = await getDB();

  if (status) {
    const validStatus = ['pending', 'confirmed', 'delivering', 'completed', 'cancelled'];
    if (!validStatus.includes(status)) {
      return res.status(400).json({ success: false, message: '无效状态' });
    }
    db.prepare('UPDATE orders SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?')
      .run(status, req.params.id);
  }

  if (payment_status) {
    db.prepare('UPDATE orders SET payment_status = ? WHERE id = ?')
      .run(payment_status, req.params.id);
  }

  res.json({ success: true, message: '状态已更新' });
});

app.get('/api/admin/products', adminAuth, async (req, res) => {
  const db = await getDB();
  const products = db.prepare('SELECT * FROM products ORDER BY id').all();
  res.json({ success: true, data: products });
});

app.put('/api/admin/products/:id', adminAuth, async (req, res) => {
  const { name, price, stock, active } = req.body;
  const db = await getDB();
  const updates = [];
  const params = [];

  if (name !== undefined) { updates.push('name = ?'); params.push(name); }
  if (price !== undefined) { updates.push('price = ?'); params.push(price); }
  if (stock !== undefined) { updates.push('stock = ?'); params.push(stock); }
  if (active !== undefined) { updates.push('active = ?'); params.push(active); }

  if (!updates.length) return res.status(400).json({ success: false, message: '无更新内容' });
  params.push(req.params.id);
  db.prepare(`UPDATE products SET ${updates.join(', ')} WHERE id = ?`).run(...params);
  res.json({ success: true, message: '已更新' });
});

app.post('/api/admin/products', adminAuth, async (req, res) => {
  const { name, brand, spec, price, stock } = req.body;
  if (!name || !brand || !price) {
    return res.status(400).json({ success: false, message: '请填写完整信息' });
  }
  const db = await getDB();
  const result = db.prepare('INSERT INTO products (name, brand, spec, price, stock) VALUES (?, ?, ?, ?, ?)')
    .run(name, brand, spec || '18.9L', price, stock || 0);
  res.json({ success: true, data: { id: result.lastInsertRowid } });
});

app.get('/api/admin/dashboard', adminAuth, async (req, res) => {
  const db = await getDB();
  const today = new Date().toISOString().slice(0, 10);

  const todayOrders = db.prepare("SELECT COUNT(*) as count, COALESCE(SUM(total_price), 0) as revenue FROM orders WHERE DATE(created_at) = ?").get(today);
  const pendingOrders = db.prepare("SELECT COUNT(*) as count FROM orders WHERE status = 'pending'").get();
  const totalOrders = db.prepare("SELECT COUNT(*) as count, COALESCE(SUM(total_price), 0) as revenue FROM orders").get();
  const products = db.prepare("SELECT * FROM products WHERE active = 1").all();

  res.json({
    success: true,
    data: {
      today: { orders: todayOrders.count, revenue: todayOrders.revenue },
      pending: pendingOrders.count,
      total: { orders: totalOrders.count, revenue: totalOrders.revenue },
      products
    }
  });
});

app.put('/api/admin/settings', adminAuth, async (req, res) => {
  const db = await getDB();
  for (const [key, value] of Object.entries(req.body)) {
    db.prepare('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)').run(key, value);
  }
  res.json({ success: true, message: '设置已保存' });
});

// ============ 页面路由 ============
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ============ 启动 ============
async function start() {
  await getDB(); // 确保数据库初始化完成
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚰 桶装水配送系统已启动: http://localhost:${PORT}`);
    console.log(`📱 客户端: http://localhost:${PORT}`);
    console.log(`🔧 管理后台: http://localhost:${PORT}/admin`);
    console.log(`🔑 管理密码: ${ADMIN_PASS}`);
  });
}

start().catch(err => {
  console.error('❌ 启动失败:', err);
  process.exit(1);
});
