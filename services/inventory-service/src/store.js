// Reads/writes the `products` table defined in database/schema.sql.

const pool = require('./db');

async function listProducts() {
  const [rows] = await pool.query(
    `SELECT p.id, p.sku, p.name, p.category_id, p.supplier_id, p.unit_price,
            p.quantity_in_stock, p.reorder_level, c.name AS category_name
     FROM products p
     JOIN categories c ON c.id = p.category_id
     ORDER BY p.name`
  );
  return rows;
}

async function getProductById(id) {
  const [rows] = await pool.query(
    `SELECT p.id, p.sku, p.name, p.category_id, p.supplier_id, p.unit_price,
            p.quantity_in_stock, p.reorder_level, c.name AS category_name
     FROM products p
     JOIN categories c ON c.id = p.category_id
     WHERE p.id = ?`,
    [id]
  );
  return rows[0];
}

async function createProduct({ sku, name, categoryId, supplierId, unitPrice, quantityInStock, reorderLevel }) {
  const [result] = await pool.query(
    `INSERT INTO products (sku, name, category_id, supplier_id, unit_price, quantity_in_stock, reorder_level)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [sku, name, categoryId, supplierId ?? null, unitPrice, quantityInStock ?? 0, reorderLevel ?? 10]
  );
  return getProductById(result.insertId);
}

module.exports = { listProducts, getProductById, createProduct };
