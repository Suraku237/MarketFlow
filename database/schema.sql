-- ============================================================================
-- SmartStock — Week 2: Database Design & Management
-- Combined relational schema (MySQL 8 dialect)
--
-- Modules covered (mirrors the exam's Academic / Finance / HR split):
--   1. INVENTORY     -> categories, suppliers, products, stock_movements
--   2. SALES         -> sales, sale_items, payments, demand_forecasts
--   3. STAFF/PAYROLL -> users (shared with auth-service), payroll_runs, payslips
--
-- Design notes:
--   * Fixed value-sets (role, status, movement_type, method) use native
--     MySQL ENUM types instead of CHECK constraints.
--   * Money columns use DECIMAL(10,2), not FLOAT/REAL, to avoid rounding
--     error on currency values.
--   * This file is only ever run once, by the MySQL container's own
--     docker-entrypoint-initdb.d mechanism against a freshly-created empty
--     data volume — so statements are plain CREATE TABLE, not
--     "IF NOT EXISTS": on a from-scratch container this always runs clean.
--   * Every table is in Third Normal Form (3NF): each column depends on the
--     whole primary key and nothing but the key (no repeating groups, no
--     transitive dependencies — e.g. product price lives only in `products`,
--     never copied into `sale_items` twice; `sale_items.unit_price` is kept
--     deliberately as a *price snapshot at time of sale*, which is not a
--     3NF violation since it represents a historical fact, not a duplicate
--     of the current `products.unit_price`).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SHARED: users (staff / auth-service identities; also referenced by payroll)
-- ----------------------------------------------------------------------------
CREATE TABLE users (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('admin', 'cashier') NOT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- MODULE 1: INVENTORY
-- ----------------------------------------------------------------------------
CREATE TABLE categories (
    id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE suppliers (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    address       VARCHAR(255),
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE products (
    id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sku               VARCHAR(50)  NOT NULL UNIQUE,
    name              VARCHAR(255) NOT NULL,
    category_id       INT UNSIGNED NOT NULL,
    supplier_id       INT UNSIGNED,
    unit_price        DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    quantity_in_stock INT NOT NULL DEFAULT 0 CHECK (quantity_in_stock >= 0),
    reorder_level     INT NOT NULL DEFAULT 10 CHECK (reorder_level >= 0),
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id),
    CONSTRAINT fk_products_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
) ENGINE=InnoDB;

CREATE TABLE stock_movements (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id    INT UNSIGNED NOT NULL,
    change_qty    INT NOT NULL,
    movement_type ENUM('RECEIPT', 'SALE', 'ADJUSTMENT', 'RETURN') NOT NULL,
    reference     VARCHAR(100),
    created_by    INT UNSIGNED,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stockmov_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_stockmov_user    FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- MODULE 2: SALES
-- ----------------------------------------------------------------------------
CREATE TABLE sales (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cashier_id   INT UNSIGNED NOT NULL,
    sale_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    status       ENUM('pending', 'paid', 'cancelled') NOT NULL DEFAULT 'pending',
    CONSTRAINT fk_sales_cashier FOREIGN KEY (cashier_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE sale_items (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sale_id    INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    quantity   INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),  -- price snapshot at sale time
    subtotal   DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
    CONSTRAINT fk_saleitems_sale    FOREIGN KEY (sale_id) REFERENCES sales(id),
    CONSTRAINT fk_saleitems_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;

CREATE TABLE payments (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sale_id        INT UNSIGNED NOT NULL UNIQUE,  -- 1:1 with sales
    momo_reference VARCHAR(100),
    amount         DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    method         ENUM('momo', 'cash', 'card') NOT NULL DEFAULT 'momo',
    status         ENUM('pending', 'approved', 'declined') NOT NULL DEFAULT 'pending',
    paid_at        DATETIME,
    CONSTRAINT fk_payments_sale FOREIGN KEY (sale_id) REFERENCES sales(id)
) ENGINE=InnoDB;

CREATE TABLE demand_forecasts (
    id                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id         INT UNSIGNED NOT NULL,
    forecast_date      DATE NOT NULL,
    predicted_quantity INT NOT NULL CHECK (predicted_quantity >= 0),
    model_version      VARCHAR(20) NOT NULL DEFAULT 'v1',
    created_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_forecast_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- MODULE 3: STAFF & PAYROLL
-- ----------------------------------------------------------------------------
CREATE TABLE payroll_runs (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    period_start DATE NOT NULL,
    period_end   DATE NOT NULL,
    run_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status       ENUM('draft', 'processed', 'paid') NOT NULL DEFAULT 'draft',
    created_by   INT UNSIGNED,
    CONSTRAINT fk_payrollrun_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE payslips (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payroll_run_id INT UNSIGNED NOT NULL,
    staff_id       INT UNSIGNED NOT NULL,
    base_salary    DECIMAL(10,2) NOT NULL CHECK (base_salary >= 0),
    deductions     DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (deductions >= 0),
    net_pay        DECIMAL(10,2) NOT NULL CHECK (net_pay >= 0),
    momo_reference VARCHAR(100),
    status         ENUM('pending', 'paid') NOT NULL DEFAULT 'pending',
    UNIQUE KEY uq_payslip_run_staff (payroll_run_id, staff_id),
    CONSTRAINT fk_payslip_run   FOREIGN KEY (payroll_run_id) REFERENCES payroll_runs(id),
    CONSTRAINT fk_payslip_staff FOREIGN KEY (staff_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- ============================================================================
-- INDEXES — Build Task 5: "add an index to at least 2 tables that will be
-- searched often". Chosen for the queries the demo actually needs to run
-- fast: looking a product up by name, listing a product's stock history,
-- listing a cashier's sales by date, and looking up a staff member's payslips.
-- ============================================================================
CREATE INDEX idx_products_name           ON products(name);
CREATE INDEX idx_products_category       ON products(category_id);
CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
CREATE INDEX idx_sales_sale_date         ON sales(sale_date);
CREATE INDEX idx_sales_cashier           ON sales(cashier_id);
CREATE INDEX idx_sale_items_sale         ON sale_items(sale_id);
CREATE INDEX idx_demand_forecasts_product ON demand_forecasts(product_id);
CREATE INDEX idx_payslips_staff          ON payslips(staff_id);
-- Note: users.email, products.sku and payments.sale_id already have an
-- implicit unique index from their UNIQUE constraints, so no separate
-- CREATE INDEX is needed there.
