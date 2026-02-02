// ============ 状态管理 ============
const cart = {};     // { productId: quantity }
let products = [];
let settings = {};

// ============ 初始化 ============
async function init() {
  try {
    const [prodRes, settRes] = await Promise.all([
      fetch('/api/products').then(r => r.json()),
      fetch('/api/settings').then(r => r.json())
    ]);

    products = prodRes.data || [];
    settings = settRes.data || {};

    if (settings.shop_name) {
      document.getElementById('shopName').textContent = settings.shop_name;
      document.title = settings.shop_name;
    }

    if (settings.announcement) {
      document.getElementById('announcement').textContent = settings.announcement;
      document.getElementById('noticeBar').style.display = 'flex';
      document.getElementById('noticeText').textContent = settings.announcement;
    }

    renderProducts();
    renderStreetOptions();
  } catch (err) {
    showToast('加载失败，请刷新重试');
  }
}

// ============ 渲染商品 ============
function renderProducts() {
  const container = document.getElementById('productList');
  container.innerHTML = products.map(p => `
    <div class="product-card" data-id="${p.id}">
      <div class="product-info">
        <h3>${p.name}</h3>
        <div class="spec">${p.brand} · ${p.spec}</div>
        <div class="price">${p.price}</div>
        <div class="stock">库存：${p.stock > 0 ? p.stock + ' 桶' : '暂时缺货'}</div>
      </div>
      <div class="quantity-control">
        <button class="qty-btn minus" onclick="changeQty(${p.id}, -1)" ${!cart[p.id] ? 'style="visibility:hidden"' : ''}>−</button>
        <span class="qty-num">${cart[p.id] || 0}</span>
        <button class="qty-btn plus" onclick="changeQty(${p.id}, 1)" ${p.stock <= 0 ? 'disabled' : ''}>+</button>
      </div>
    </div>
  `).join('');
}

// ============ 配送街道选项 ============
function renderStreetOptions() {
  const select = document.getElementById('customerStreet');
  const areas = (settings.delivery_areas || '羊坊店街道,万寿路街道,永定路街道,八里庄街道').split(',');
  areas.forEach(area => {
    const opt = document.createElement('option');
    opt.value = area.trim();
    opt.textContent = area.trim();
    select.appendChild(opt);
  });
}

// ============ 数量控制 ============
function changeQty(productId, delta) {
  const product = products.find(p => p.id === productId);
  if (!product) return;

  const current = cart[productId] || 0;
  const next = current + delta;

  if (next < 0) return;
  if (next > product.stock) {
    showToast('库存不足');
    return;
  }

  if (next === 0) {
    delete cart[productId];
  } else {
    cart[productId] = next;
  }

  renderProducts();
  updateCart();
}

// ============ 更新购物车 ============
function updateCart() {
  const totalItems = Object.values(cart).reduce((s, q) => s + q, 0);
  const totalPrice = Object.entries(cart).reduce((s, [id, qty]) => {
    const p = products.find(p => p.id === Number(id));
    return s + (p ? p.price * qty : 0);
  }, 0);

  const cartBar = document.getElementById('cartBar');
  const orderSection = document.getElementById('orderSection');

  if (totalItems > 0) {
    cartBar.style.display = 'flex';
    orderSection.style.display = 'block';
    document.getElementById('cartCount').textContent = totalItems;
    document.getElementById('cartTotal').textContent = totalPrice.toFixed(0);
  } else {
    cartBar.style.display = 'none';
    orderSection.style.display = 'none';
  }
}

// ============ 提交订单 ============
async function submitOrder() {
  const name = document.getElementById('customerName').value.trim();
  const phone = document.getElementById('customerPhone').value.trim();
  const street = document.getElementById('customerStreet').value;
  const address = document.getElementById('customerAddress').value.trim();
  const note = document.getElementById('customerNote').value.trim();

  if (!name) { showToast('请输入姓名'); return; }
  if (!/^1[3-9]\d{9}$/.test(phone)) { showToast('请输入正确的手机号'); return; }
  if (!street) { showToast('请选择配送街道'); return; }
  if (!address) { showToast('请输入详细地址'); return; }

  const items = Object.entries(cart).map(([id, quantity]) => ({
    product_id: Number(id),
    quantity
  }));

  if (!items.length) { showToast('请先选择商品'); return; }

  const submitBtn = document.getElementById('submitBtn');
  submitBtn.disabled = true;
  submitBtn.textContent = '提交中...';

  try {
    const res = await fetch('/api/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ customer_name: name, phone, address, street, note, items })
    });

    const data = await res.json();
    if (data.success) {
      document.getElementById('orderNo').textContent = data.data.order_no;
      document.getElementById('orderTotal').textContent = '¥' + data.data.total_price;
      document.getElementById('successModal').style.display = 'flex';

      // 清空购物车
      Object.keys(cart).forEach(k => delete cart[k]);
      renderProducts();
      updateCart();

      // 保存手机号方便下次用
      localStorage.setItem('water_phone', phone);
      localStorage.setItem('water_name', name);
    } else {
      showToast(data.message || '下单失败');
    }
  } catch (err) {
    showToast('网络错误，请重试');
  } finally {
    submitBtn.disabled = false;
    submitBtn.textContent = '提交订单';
  }
}

// ============ 关闭弹窗 ============
function closeModal() {
  document.getElementById('successModal').style.display = 'none';
}

// ============ 查询订单 ============
async function queryOrders() {
  const phone = document.getElementById('queryPhone').value.trim();
  if (!/^1[3-9]\d{9}$/.test(phone)) {
    showToast('请输入正确的手机号');
    return;
  }

  const container = document.getElementById('queryResult');
  container.innerHTML = '<div class="loading">查询中...</div>';

  try {
    const res = await fetch(`/api/orders/query?phone=${phone}`);
    const data = await res.json();

    if (!data.data?.length) {
      container.innerHTML = '<div class="empty-state"><div class="empty-icon">📦</div>暂无订单记录</div>';
      return;
    }

    container.innerHTML = data.data.map(o => `
      <div class="order-card">
        <div class="order-header">
          <span class="order-no">${o.order_no}</span>
          <span class="status-badge status-${o.status}">${statusText(o.status)}</span>
        </div>
        <div class="order-items">${o.items_desc}</div>
        <div class="order-total">¥${o.total_price}</div>
        <div class="order-time">${formatTime(o.created_at)}</div>
      </div>
    `).join('');
  } catch (err) {
    container.innerHTML = '<div class="empty-state">查询失败，请重试</div>';
  }
}

// ============ 工具函数 ============
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

// ============ 恢复上次信息 ============
window.addEventListener('DOMContentLoaded', () => {
  const savedPhone = localStorage.getItem('water_phone');
  const savedName = localStorage.getItem('water_name');
  if (savedPhone) document.getElementById('customerPhone').value = savedPhone;
  if (savedName) document.getElementById('customerName').value = savedName;
  if (savedPhone) document.getElementById('queryPhone').value = savedPhone;
  init();
});
