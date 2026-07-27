-- ============================================================================
-- SmartStock — sample seed data (for local demo / evaluation only)
-- Runs once, right after schema.sql, via the MySQL container's
-- docker-entrypoint-initdb.d mechanism.
-- ============================================================================

-- Staff (password hashes are placeholders — real hashes come from auth-service;
-- register real demo accounts through the Week 1 API instead of logging in
-- with these rows directly).
INSERT INTO users (name, email, password_hash, role) VALUES
    ('Rayan Kwete',   'admin@smartstock.local',   '$2a$10$placeholderadminhash', 'admin'),
    ('Neil Marshall', 'cashier@smartstock.local', '$2a$10$placeholdercashhash',  'cashier');

-- Inventory
INSERT INTO categories (name) VALUES ('Beverages'), ('Bakery'), ('Household');

INSERT INTO suppliers (name, contact_email, contact_phone, address) VALUES
    ('Douala Beverage Co.', 'sales@doualabev.cm', '+237670000001', 'Douala, Cameroon'),
    ('Yaounde Bakers Ltd.', 'orders@ydebakers.cm', '+237670000002', 'Yaounde, Cameroon');

INSERT INTO products (sku, name, category_id, supplier_id, unit_price, quantity_in_stock, reorder_level) VALUES
    ('BEV-001', 'Mineral Water 1.5L', 1, 1, 500,  120, 30),
    ('BEV-002', 'Orange Juice 1L',    1, 1, 1200,  40, 15),
    ('BAK-001', 'Sliced Bread',       2, 2, 800,   25, 10),
    ('HH-001',  'Dish Soap 500ml',    3, NULL, 1500, 60, 20);

INSERT INTO stock_movements (product_id, change_qty, movement_type, reference, created_by) VALUES
    (1, 150, 'RECEIPT', 'PO-1001', 1),
    (1, -30, 'SALE',    'SALE-1',  2),
    (3, 40,  'RECEIPT', 'PO-1002', 1);

-- Sales
INSERT INTO sales (cashier_id, total_amount, status) VALUES
    (2, 2300, 'paid');

INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, subtotal) VALUES
    (1, 1, 3, 500, 1500),
    (1, 3, 1, 800, 800);

INSERT INTO payments (sale_id, momo_reference, amount, method, status, paid_at) VALUES
    (1, 'MOMO-REF-0001', 2300, 'momo', 'approved', NOW());

INSERT INTO demand_forecasts (product_id, forecast_date, predicted_quantity, model_version) VALUES
    (1, DATE_ADD(CURDATE(), INTERVAL 7 DAY), 100, 'v1'),
    (2, DATE_ADD(CURDATE(), INTERVAL 7 DAY), 35,  'v1');

-- Payroll
INSERT INTO payroll_runs (period_start, period_end, status, created_by) VALUES
    (DATE_FORMAT(CURDATE(), '%Y-%m-01'), LAST_DAY(CURDATE()), 'processed', 1);

INSERT INTO payslips (payroll_run_id, staff_id, base_salary, deductions, net_pay, momo_reference, status) VALUES
    (1, 2, 150000, 15000, 135000, 'MOMO-PAY-0001', 'paid');
