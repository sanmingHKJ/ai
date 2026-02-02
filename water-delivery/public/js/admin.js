// ============ 状态 ============
let token = localStorage.getItem('water_admin_token') || '';
let currentPage = 'Dashboard';
let currentOrderFilter = 'all';

const API = {
  headers() { return { 'Content-Type': 'application/json', 'X-Admin-Token': token }; },
  async get(url) { const r = await fetch(url, { headers: this.headers() }); return r.json(); },
  async post(url, body) { const r = await fetch(url, { method: 'POST', headers: this.headers(), body: JSON.stringify(body) }); return r.json(); },
  async put(url, body) { const r = await fetch(url, { method: 'PUT', headers: this.headers(), body: JSON.stringify(body) }); return r.json(); }
};

// ============ 登录 ============
async function doLogin() {
  const pass = document.getElementById('loginPass').value;
  if (!pass) return showToast('请输入密码');

  const res = await fetch('/api/admin/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ password: pass })
  }).then(r => r.json());

  if (res.success) {
    token = res.token;
    localStorage.setItem('water_admin_token', token);
    showMainApp();
  } else {
    showToast('密码错误');
  }
}

function showMainApp() {
  document.getElementById('loginPage').style.display = 'none';
  document.getElementById('mainApp').style.display = 'block';
  loadDashboard();
}

// ============ 页面切换 ============
function switchPage(page, el) {
  currentPage = page;
  document.querySelectorAll('.page').forEach(p => p.style.display = 'none');
  document.getElementById('page' + page).style.display = 'block';
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  if (el) el.classList.add('active');

  if (page === 'Dashboard') loadDashboard();
  else if (page === 'Orders') loadOrders();
  else if (page === 'Stock') loadStock();
  else if (page === 'Settings') loadSettings();
}

function refreshData() {
  switchPage(currentPage, document.querySelector('.nav-item.active'));
  showToast('已刷新');
}

// ============ 仪表盘 ============
async function loadDashboard() {
  try {
    const res = await API.get('/api/admin/dashboard');
    if (!res.success) return;

    const d = res.data;
    document.getElementById('statsGrid').innerHTML = `
      <div class="stat-card">
        <div class="stat-num">${d.today.orders}</div>
        <div class="stat-label">今日订单</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">¥${d.today.revenue.toFixed(0)}</div>
        <div class="stat-label">今日收入</div>
      </div>
      <div class="stat-card warning">
        <div class="stat-num">${d.pending}</div>
        <div class="stat-label">待处理</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">${d.total.orders}</div>
        <div class="stat-label">总订单数</div>
      </div>
    `;

    // 加载待处理订单
    const ordersRes = await API.get('/api/admin/orders?status=pending&limit=10');
    renderOrderList(ordersRes.data || [], document.getElementById('pendingOrders'));
  } catch (err) {
    showToast('加载失败');
  }
}

// ============ 订单管理 ============
async function loadOrders() {
  try {
    const res = await API.get(`/api/admin/orders?status=${currentOrderFilter}&limit=50`);
    renderOrderList(res.data || [], document.getElementById('orderList'));
  } catch (err) {
    showToast('加载失败');
  }
}

function filterOrders(status, el) {
  currentOrderFilter = status;
  document.querySelectorAll('#orderTabs .tab').forEach(t => t.classList.remove('active'));
  if (el) el.classList.add('active');
  loadOrders();
}

function renderOrderList(orders, container) {
  if (!orders.length) {
    container.innerHTML = '<div class="empty-state"><div class="empty-icon">📭</div>暂无订单</div>';
    return;
  }

  container.innerHTML = orders.map(o => `
    <div class="admin-order-card" id="order-${o.id}">
      <div class="row">
        <span class="customer">${o.customer_name}</span>
        <span class="status-badge status-${o.status}">${statusText(o.status)}</span>
      </div>
      <div class="row">
        <span class="order-no" style="font-size:12px;color:var(--text-light)">${o.order_no}</span>
        <span style="font-size:12px;color:var(--text-light)">${o.payment_status === 'paid' ? '✅ 已付' : '⏳ 未付'}</span>
      </div>
      <div class="detail">
        📦 ${o.items_desc}<br>
        📍 ${o.street} ${o.address}<br>
        📞 <a href="tel:${o.phone}">${o.phone}</a>
        ${o.note ? '<br>📝 ' + o.note : ''}
      </div>
      <div class="row">
        <span class="order-total" style="font-size:18px;font-weight:700;color:var(--danger)">¥${o.total_price}</span>
        <span style="font-size:12px;color:var(--text-light)">${formatTime(o.created_at)}</span>
      </div>
      <div class="actions">
        ${o.status === 'pending' ? `
          <button class="action-btn confirm" onclick="updateOrder(${o.id}, 'confirmed')">✓ 确认</button>
          <button class="action-btn cancel" onclick="updateOrder(${o.id}, 'cancelled')">✕ 取消</button>
        ` : ''}
        ${o.status === 'confirmed' ? `
          <button class="action-btn deliver" onclick="updateOrder(${o.id}, 'delivering')">🚚 配送</button>
        ` : ''}
        ${o.status === 'delivering' ? `
          <button class="action-btn complete" onclick="updateOrder(${o.id}, 'completed')">✓ 完成</button>
        ` : ''}
        ${o.payment_status !== 'paid' ? `
          <button class="action-btn paid" onclick="markPaid(${o.id})">💰 标记已付</button>
        ` : ''}
        <a class="action-btn call" href="tel:${o.phone}">📞 拨打</a>
      </div>
    </div>
  `).join('');
}

async function updateOrder(id, status) {
  const res = await API.put(`/api/admin/orders/${id}/status`, { status });
  if (res.success) {
    showToast('已更新');
    refreshData();
  } else {
    showToast(res.message || '操作失败');
  }
}

async function markPaid(id) {
  const res = await API.put(`/api/admin/orders/${id}/status`, {
    status: undefined,
    payment_status: 'paid'
  });
  if (res.success) {
    showToast('已标记为已付款');
    refreshData();
  }
}

// ============ 库存管理 ============
async function loadStock() {
  try {
    const res = await API.get('/api/admin/products');
    const products = res.data || [];

    document.getElementById('stockList').innerHTML = products.map(p => `
      <div class="stock-card">
        <div class="stock-header">
          <h4>${p.name}</h4>
          <span class="status-badge ${p.active ? 'status-confirmed' : 'status-cancelled'}">
            ${p.active ? '上架' : '下架'}
          </span>
        </div>
        <div class="stock-input-row">
          <label>单价 ¥</label>
          <input type="number" id="price-${p.id}" value="${p.price}" step="0.5" min="0">
          <label>库存</label>
          <input type="number" id="stock-${p.id}" value="${p.stock}" min="0">
          <button class="btn-small" onclick="updateProduct(${p.id})">保存</button>
          <button class="action-btn ${p.active ? 'cancel' : 'confirm'}" 
                  onclick="toggleProduct(${p.id}, ${p.active ? 0 : 1})">
            ${p.active ? '下架' : '上架'}
          </button>
        </div>
      </div>
    `).join('');
  } catch (err) {
    showToast('加载失败');
  }
}

async function updateProduct(id) {
  const price = parseFloat(document.getElementById(`price-${id}`).value);
  const stock = parseInt(document.getElementById(`stock-${id}`).value);
  const res = await API.put(`/api/admin/products/${id}`, { price, stock });
  showToast(res.success ? '已保存' : '保存失败');
}

async function toggleProduct(id, active) {
  const res = await API.put(`/api/admin/products/${id}`, { active });
  if (res.success) { showToast(active ? '已上架' : '已下架'); loadStock(); }
}

// ============ 设置 ============
async function loadSettings() {
  const res = await API.get('/api/settings');
  const s = res.data || {};
  document.getElementById('setShopName').value = s.shop_name || '';
  document.getElementById('setPhone').value = s.phone || '';
  document.getElementById('setAreas').value = s.delivery_areas || '';
  document.getElementById('setHours').value = s.business_hours || '';
  document.getElementById('setAnnouncement').value = s.announcement || '';
}

async function saveSettings() {
  const settings = {
    shop_name: document.getElementById('setShopName').value,
    phone: document.getElementById('setPhone').value,
    delivery_areas: document.getElementById('setAreas').value,
    business_hours: document.getElementById('setHours').value,
    announcement: document.getElementById('setAnnouncement').value
  };
  const res = await API.put('/api/admin/settings', settings);
  showToast(res.success ? '设置已保存' : '保存失败');
}

// ============ 推送通知 ============
async function subscribePush() {
  if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
    showToast('您的浏览器不支持推送通知');
    return;
  }

  try {
    const keyRes = await fetch('/api/push/vapid-key').then(r => r.json());
    if (!keyRes.key) {
      showToast('推送服务未配置');
      return;
    }

    const reg = await navigator.serviceWorker.register('/sw.js');
    const sub = await reg.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(keyRes.key)
    });

    const res = await fetch('/api/push/subscribe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(sub.toJSON())
    }).then(r => r.json());

    showToast(res.success ? '推送已开启 🔔' : '开启失败');
  } catch (err) {
    showToast('开启推送失败：' + err.message);
  }
}

function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
  const raw = atob(base64);
  return Uint8Array.from([...raw].map(c => c.charCodeAt(0)));
}

// ============ 工具 ============
const STATUS_MAP = {
  pending: '待确认', confirmed: '已确认', delivering: '配送中',
  completed: '已完成', cancelled: '已取消'
};

function statusText(s) { return STATUS_MAP[s] || s; }

function formatTime(t) {
  if (!t) return '';
  const d = new Date(t + (t.includes('Z') ? '' : 'Z'));
  return `${d.getMonth()+1}/${d.getDate()} ${d.getHours().toString().padStart(2,'0')}:${d.getMinutes().toString().padStart(2,'0')}`;
}

function showToast(msg) {
  const el = document.createElement('div');
  el.className = 'toast';
  el.textContent = msg;
  document.body.appendChild(el);
  setTimeout(() => el.remove(), 2500);
}

// ============ 自动登录 / 初始化 ============
window.addEventListener('DOMContentLoaded', () => {
  if (token) {
    // 验证 token
    fetch('/api/admin/dashboard', { headers: { 'X-Admin-Token': token } })
      .then(r => r.json())
      .then(res => {
        if (res.success) showMainApp();
        else { localStorage.removeItem('water_admin_token'); token = ''; }
      });
  }
});

// ============ 自动刷新 ============
setInterval(() => {
  if (currentPage === 'Dashboard' && token) loadDashboard();
}, 30000); // 30秒刷新一次
