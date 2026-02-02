const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

const DB_PATH = process.env.NODE_ENV === 'production' 
  ? path.join('/tmp', 'water.db') 
  : path.join(__dirname, 'water.db');

let db;

class DBWrapper {
  constructor(database) {
    this._db = database;
    this._inTransaction = false;
  }

  exec(sql) {
    this._db.run(sql);
    if (!this._inTransaction) this._save();
  }

  prepare(sql) {
    const self = this;
    return {
      run(...params) {
        self._db.run(sql, params);
        const lastId = self._db.exec('SELECT last_insert_rowid() as id');
        const lastInsertRowid = lastId[0]?.values[0]?.[0] || 0;
        if (!self._inTransaction) self._save();
        return { lastInsertRowid };
      },
      get(...params) {
        const stmt = self._db.prepare(sql);
        if (params.length) stmt.bind(params);
        if (stmt.step()) {
          const cols = stmt.getColumnNames();
          const vals = stmt.get();
          stmt.free();
          const row = {};
          cols.forEach((c, i) => row[c] = vals[i]);
          return row;
        }
        stmt.free();
        return undefined;
      },
      all(...params) {
        const results = [];
        const stmt = self._db.prepare(sql);
        if (params.length) stmt.bind(params);
        while (stmt.step()) {
          const cols = stmt.getColumnNames();
          const vals = stmt.get();
          const row = {};
          cols.forEach((c, i) => row[c] = vals[i]);
          results.push(row);
        }
        stmt.free();
        return results;
      }
    };
  }

  transaction(fn) {
    const self = this;
    return (...args) => {
      self._inTransaction = true;
      self._db.run('BEGIN TRANSACTION');
      try {
        const result = fn(...args);
        self._db.run('COMMIT');
        self._inTransaction = false;
        self._save();
        return result;
      } catch (e) {
        self._db.run('ROLLBACK');
        self._inTransaction = false;
        throw e;
      }
    };
  }

  pragma(sql) {
    this._db.run(`PRAGMA ${sql}`);
  }

  _save() {
    const data = this._db.export();
    const buffer = Buffer.from(data);
    fs.writeFileSync(DB_PATH, buffer);
  }
}

async function getDB() {
  if (db) return db;

  const SQL = await initSqlJs();

  let database;
  if (fs.existsSync(DB_PATH)) {
    const fileBuffer = fs.readFileSync(DB_PATH);
    database = new SQL.Database(fileBuffer);
  } else {
    database = new SQL.Database();
  }

  db = new DBWrapper(database);

  db.exec(`
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      brand TEXT NOT NULL,
      spec TEXT DEFAULT '18.9L',
      price REAL NOT NULL,
      stock INTEGER DEFAULT 100,
      image TEXT,
      active INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_no TEXT UNIQUE NOT NULL,
      customer_name TEXT NOT NULL,
      phone TEXT NOT NULL,
      address TEXT NOT NULL,
      street TEXT NOT NULL,
      note TEXT,
      total_price REAL NOT NULL,
      status TEXT DEFAULT 'pending',
      payment_status TEXT DEFAULT 'unpaid',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      price REAL NOT NULL,
      quantity INTEGER NOT NULL,
      FOREIGN KEY (order_id) REFERENCES orders(id)
    );
    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT
    );
    CREATE TABLE IF NOT EXISTS push_subscriptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      endpoint TEXT UNIQUE NOT NULL,
      keys_p256dh TEXT,
      keys_auth TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  `);

  const productCount = db.prepare('SELECT COUNT(*) as count FROM products').get();
  if (productCount.count === 0) {
    db.prepare('INSERT INTO products (name, brand, spec, price, stock) VALUES (?, ?, ?, ?, ?)').run('农夫山泉桶装水', '农夫山泉', '18.9L', 25, 100);
    db.prepare('INSERT INTO products (name, brand, spec, price, stock) VALUES (?, ?, ?, ?, ?)').run('怡宝桶装水', '怡宝', '18.9L', 22, 100);
  }

  const settingsCount = db.prepare('SELECT COUNT(*) as count FROM settings').get();
  if (settingsCount.count === 0) {
    db.prepare('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)').run('shop_name', '海淀羊坊店桶装水配送');
    db.prepare('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)').run('phone', '15439308410');
    db.prepare('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)').run('delivery_areas', '羊坊店街道,万寿路街道,永定路街道,八里庄街道');
    db.prepare('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)').run('business_hours', '08:00-20:00');
    db.prepare('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)').run('min_order', '1');
    db.prepare('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)').run('announcement', '当天下单，当天配送！服务电话：15439308410');
  }

  return db;
}

module.exports = { getDB };
