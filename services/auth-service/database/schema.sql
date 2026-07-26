-- ============================================================================
-- SmartStock — Week 2: Database Design & Management
-- Combined relational schema (SQLite dialect)
--
-- Modules covered (mirrors the exam's Academic / Finance / HR split):
--   1. INVENTORY   -> categories, suppliers, products, stock_movements
--   2. SALES       -> sales, sale_items, payments, demand_forecasts
--   3. STAFF/PAYROLL -> users (shared with auth-service), payroll_runs, payslips
--
-- Design notes:
--   * SQLite has no native ENUM type, so fixed value-sets are enforced with
--     CHECK constraints instead (role, status, movement_type, method).
--   * All timestamps are stored as ISO-8601 TEXT via datetime('now').
--   * Every table is in Third Normal Form (3NF): each column depends on the
--     whole primary key and nothing but the key (no repeating groups, no
--     transitive dependencies — e.g. product price lives only in `products`,
--     never copied into `sale_items` twice; `sale_items.unit_price` is kept
--     deliberately as a *price snapshot at time of sale*, which is not a
--     3NF violation since it represents a historical fact, not a duplicate
--     of the current `products.unit_price`).
--   * Foreign keys are enforced at runtime; enable them per-connection with:
--       PRAGMA foreign_keys = ON;
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ----------------------------------------------------------------------------
-- SHARED: users (staff / auth-service identities; also referenced by payroll)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT    NOT NULL,
    email         TEXT    NOT NULL UNIQUE,
    password_hash TEXT    NOT NULL,
    role          TEXT    NOT NULL CHECK (role IN ('admin', 'cashier')),
    created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ----------------------------------------------------------------------------
-- MODULE 1: INVENTORY
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT    NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS suppliers (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT    NOT NULL,
    contact_email TEXT,
    contact_phone TEXT,
    address       TEXT,
    created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS products (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    sku               TEXT    NOT NULL UNIQUE,
    name              TEXT    NOT NULL,
    category_id       INTEGER NOT NULL REFERENCES categories(id),
    supplier_id       INTEGER REFERENCES suppliers(id),
    unit_price        REAL    NOT NULL CHECK (unit_price >= 0),
    quantity_in_stock INTEGER NOT NULL DEFAULT 0 CHECK (quantity_in_stock >= 0),
    reorder_level     INTEGER NOT NULL DEFAULT 10 CHECK (reorder_level >= 0),
    created_at        TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at        TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS stock_movements (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id    INTEGER NOT NULL REFERENCES products(id),
    change_qty    INTEGER NOT NULL,
    movement_type TEXT    NOT NULL CHECK (movement_type IN ('RECEIPT', 'SALE', 'ADJUSTMENT', 'RETURN')),
    reference     TEXT,
    created_by    INTEGER REFERENCES users(id),
    created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ----------------------------------------------------------------------------
-- MODULE 2: SALES
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sales (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    cashier_id   INTEGER NOT NULL REFERENCES users(id),
    sale_date    TEXT    NOT NULL DEFAULT (datetime('now')),
    total_amount REAL    NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    status       TEXT    NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'cancelled'))
);

CREATE TABLE IF NOT EXISTS sale_items (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    sale_id    INTEGER NOT NULL REFERENCES sales(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity   INTEGER NOT NULL CHECK (quantity > 0),
    unit_price REAL    NOT NULL CHECK (unit_price >= 0),  -- price snapshot at sale time
    subtotal   REAL    NOT NULL CHECK (subtotal >= 0)
);

CREATE TABLE IF NOT EXISTS payments (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    sale_id        INTEGER NOT NULL UNIQUE REFERENCES sales(id),  -- 1:1 with sales
    momo_reference TEXT,
    amount         REAL    NOT NULL CHECK (amount >= 0),
    method         TEXT    NOT NULL DEFAULT 'momo' CHECK (method IN ('momo', 'cash', 'card')),
    status         TEXT    NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'declined')),
    paid_at        TEXT
);

CREATE TABLE IF NOT EXISTS demand_forecasts (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id         INTEGER NOT NULL REFERENCES products(id),
    forecast_date      TEXT    NOT NULL,
    predicted_quantity INTEGER NOT NULL CHECK (predicted_quantity >= 0),
    model_version      TEXT    NOT NULL DEFAULT 'v1',
    created_at         TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ----------------------------------------------------------------------------
-- MODULE 3: STAFF & PAYROLL
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payroll_runs (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    period_start TEXT    NOT NULL,
    period_end   TEXT    NOT NULL,
    run_date     TEXT    NOT NULL DEFAULT (datetime('now')),
    status       TEXT    NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'processed', 'paid')),
    created_by   INTEGER REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS payslips (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    payroll_run_id INTEGER NOT NULL REFERENCES payroll_runs(id),
    staff_id       INTEGER NOT NULL REFERENCES users(id),
    base_salary    REAL    NOT NULL CHECK (base_salary >= 0),
    deductions     REAL    NOT NULL DEFAULT 0 CHECK (deductions >= 0),
    net_pay        REAL    NOT NULL CHECK (net_pay >= 0),
    momo_reference TEXT,
    status         TEXT    NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid')),
    UNIQUE (payroll_run_id, staff_id)
);

-- ============================================================================
-- INDEXES — Build Task 5: "add an index to at least 2 tables that will be
-- searched often". Chosen for the queries the demo actually needs to run
-- fast: looking a product up by name, listing a product's stock history,
-- listing a cashier's sales by date, and looking up a staff member's payslips.
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_products_name           ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_category        ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_product  ON stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_sales_sale_date          ON sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_sales_cashier            ON sales(cashier_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale          ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_demand_forecasts_product ON demand_forecasts(product_id);
CREATE INDEX IF NOT EXISTS idx_payslips_staff           ON payslips(staff_id);
-- Note: users.email and products.sku already have an implicit unique index
-- from their UNIQUE constraints, so no separate CREATE INDEX is needed there.