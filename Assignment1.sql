/* ============================================================
   ElectroStore Annual Performance Review
   SQL Server Script (Schema + Sample Data + JOINs + Windows)
   ============================================================ */

---------------------------------------------------------------
-- 0) RESET (DROP TABLES)
---------------------------------------------------------------
IF OBJECT_ID('dbo.order_items', 'U') IS NOT NULL DROP TABLE dbo.order_items;
IF OBJECT_ID('dbo.orders', 'U') IS NOT NULL DROP TABLE dbo.orders;
IF OBJECT_ID('dbo.products', 'U') IS NOT NULL DROP TABLE dbo.products;
IF OBJECT_ID('dbo.customers', 'U') IS NOT NULL DROP TABLE dbo.customers;
GO

---------------------------------------------------------------
-- 1) SCHEMA (CREATE TABLES)
---------------------------------------------------------------
CREATE TABLE dbo.customers (
  customer_id  INT IDENTITY(1,1) NOT NULL,
  full_name    VARCHAR(100) NOT NULL,
  region       VARCHAR(50)  NOT NULL,
  signup_date  DATE NOT NULL,
  CONSTRAINT PK_customers PRIMARY KEY (customer_id)
);
GO

CREATE TABLE dbo.products (
  product_id   INT IDENTITY(1,1) NOT NULL,
  product_name VARCHAR(120) NOT NULL,
  category     VARCHAR(60)  NOT NULL,
  unit_price   DECIMAL(12,2) NOT NULL,
  CONSTRAINT PK_products PRIMARY KEY (product_id),
  CONSTRAINT CK_products_unit_price CHECK (unit_price >= 0)
);
GO

CREATE TABLE dbo.orders (
  order_id     INT IDENTITY(1,1) NOT NULL,
  customer_id  INT NOT NULL,
  order_date   DATE NOT NULL,
  region       VARCHAR(50) NOT NULL,
  CONSTRAINT PK_orders PRIMARY KEY (order_id),
  CONSTRAINT FK_orders_customers FOREIGN KEY (customer_id)
    REFERENCES dbo.customers(customer_id)
);
GO

CREATE TABLE dbo.order_items (
  order_item_id      INT IDENTITY(1,1) NOT NULL,
  order_id           INT NOT NULL,
  product_id         INT NOT NULL,
  quantity           INT NOT NULL,
  unit_price_at_sale DECIMAL(12,2) NOT NULL,
  CONSTRAINT PK_order_items PRIMARY KEY (order_item_id),
  CONSTRAINT FK_order_items_orders FOREIGN KEY (order_id)
    REFERENCES dbo.orders(order_id),
  CONSTRAINT FK_order_items_products FOREIGN KEY (product_id)
    REFERENCES dbo.products(product_id),
  CONSTRAINT CK_order_items_quantity CHECK (quantity > 0),
  CONSTRAINT CK_order_items_price CHECK (unit_price_at_sale >= 0)
);
GO

CREATE INDEX IX_orders_customer_id   ON dbo.orders(customer_id);
CREATE INDEX IX_orders_order_date    ON dbo.orders(order_date);
CREATE INDEX IX_order_items_order_id ON dbo.order_items(order_id);
CREATE INDEX IX_order_items_product  ON dbo.order_items(product_id);
GO

---------------------------------------------------------------
-- 2) SAMPLE DATA (FOR SCREENSHOTS)
---------------------------------------------------------------
INSERT INTO dbo.customers (full_name, region, signup_date) VALUES
('Alice Muryango',     'Kigali', '2025-01-10'),
('Patrick Habimana',   'South',  '2025-03-02'),
('Diane Uwimana',      'North',  '2025-05-15'),
('Jean Nkurunziza',    'Kigali', '2025-07-01'),
('Eric Mugabo',        'East',   '2025-08-20'),
('Sandrine Mukamana',  'West',   '2025-09-05');
GO

INSERT INTO dbo.products (product_name, category, unit_price) VALUES
('Samsung Galaxy A14',       'Phones',      180.00),
('HP Laptop 15',             'Laptops',     620.00),
('LG Smart TV 43"',          'TVs',         350.00),
('JBL Bluetooth Speaker',    'Audio',        75.00),
('Apple AirPods',            'Audio',       130.00),
('Canon Printer',            'Accessories',  95.00),
('Dell Monitor 24"',         'Accessories', 150.00);
GO

INSERT INTO dbo.orders (customer_id, order_date, region) VALUES
(1, '2025-10-02', 'Kigali'),
(2, '2025-10-15', 'South'),
(1, '2025-11-05', 'Kigali'),
(3, '2025-11-21', 'North'),
(4, '2025-12-03', 'Kigali'),
(2, '2025-12-18', 'South'),
(1, '2026-01-07', 'Kigali'),
(3, '2026-01-26', 'North');
GO

INSERT INTO dbo.order_items (order_id, product_id, quantity, unit_price_at_sale) VALUES
(1, 1, 1, 175.00),
(1, 4, 2, 70.00),
(2, 3, 1, 340.00),
(3, 2, 1, 610.00),
(3, 5, 1, 125.00),
(4, 1, 2, 178.00),
(5, 4, 1, 75.00),
(6, 3, 1, 350.00),
(6, 4, 1, 72.00),
(7, 2, 1, 600.00),
(7, 6, 1, 90.00),
(8, 1, 1, 180.00);
GO

---------------------------------------------------------------
-- 3) PART A: SQL JOINs (REQUIRED TYPES)
---------------------------------------------------------------

-- A1) INNER JOIN: valid transactions (customer + order + item + product)
SELECT
  o.order_id,
  o.order_date,
  c.full_name,
  o.region,
  p.product_name,
  oi.quantity,
  oi.unit_price_at_sale,
  (oi.quantity * oi.unit_price_at_sale) AS line_total
FROM dbo.orders o
JOIN dbo.customers c    ON c.customer_id = o.customer_id
JOIN dbo.order_items oi ON oi.order_id = o.order_id
JOIN dbo.products p     ON p.product_id = oi.product_id
ORDER BY o.order_date, o.order_id;

-- A2) LEFT JOIN: customers with no orders
SELECT
  c.customer_id,
  c.full_name,
  c.region,
  c.signup_date
FROM dbo.customers c
LEFT JOIN dbo.orders o
  ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.signup_date;

-- A3) RIGHT JOIN alternative (FULL JOIN not needed): products with no sales
SELECT
  p.product_id,
  p.product_name,
  p.category
FROM dbo.products p
LEFT JOIN dbo.order_items oi
  ON oi.product_id = p.product_id
WHERE oi.product_id IS NULL
ORDER BY p.product_name;

-- A4) FULL OUTER JOIN: include unmatched records (demo)
WITH customer_activity AS (
  SELECT DISTINCT c.customer_id, c.full_name
  FROM dbo.customers c
  LEFT JOIN dbo.orders o
    ON o.customer_id = c.customer_id
),
product_activity AS (
  SELECT DISTINCT p.product_id, p.product_name
  FROM dbo.products p
  LEFT JOIN dbo.order_items oi
    ON oi.product_id = p.product_id
)
SELECT
  ca.customer_id,
  ca.full_name,
  pa.product_id,
  pa.product_name
FROM customer_activity ca
FULL OUTER JOIN product_activity pa
  ON ca.customer_id = pa.product_id
ORDER BY
  CASE WHEN ca.customer_id IS NULL THEN 1 ELSE 0 END,
  ca.customer_id,
  CASE WHEN pa.product_id IS NULL THEN 1 ELSE 0 END,
  pa.product_id;

-- A5) SELF JOIN: customers in the same region (pairs)
SELECT
  c1.region,
  c1.full_name AS customer_a,
  c2.full_name AS customer_b
FROM dbo.customers c1
JOIN dbo.customers c2
  ON c1.region = c2.region
 AND c1.customer_id < c2.customer_id
ORDER BY c1.region, customer_a, customer_b;

---------------------------------------------------------------
-- 4) PART B: WINDOW FUNCTIONS (4 CATEGORIES)
---------------------------------------------------------------

-- Base view snippet (optional, useful for checks)
WITH sales AS (
  SELECT
    o.order_id,
    o.order_date,
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS order_month,
    o.region,
    o.customer_id,
    c.full_name,
    p.product_id,
    p.product_name,
    oi.quantity,
    oi.unit_price_at_sale,
    (oi.quantity * oi.unit_price_at_sale) AS revenue
  FROM dbo.orders o
  JOIN dbo.customers c    ON c.customer_id = o.customer_id
  JOIN dbo.order_items oi ON oi.order_id = o.order_id
  JOIN dbo.products p     ON p.product_id = oi.product_id
)
SELECT * FROM sales;

-- B1) Ranking functions: ROW_NUMBER, RANK, DENSE_RANK, PERCENT_RANK (Top N products per region)
WITH product_revenue AS (
  SELECT
    o.region,
    p.product_name,
    SUM(oi.quantity * oi.unit_price_at_sale) AS total_revenue
  FROM dbo.orders o
  JOIN dbo.order_items oi ON oi.order_id = o.order_id
  JOIN dbo.products p     ON p.product_id = oi.product_id
  GROUP BY o.region, p.product_name
),
ranked AS (
  SELECT
    region,
    product_name,
    total_revenue,
    ROW_NUMBER()   OVER (PARTITION BY region ORDER BY total_revenue DESC) AS row_num,
    RANK()         OVER (PARTITION BY region ORDER BY total_revenue DESC) AS rank_num,
    DENSE_RANK()   OVER (PARTITION BY region ORDER BY total_revenue DESC) AS dense_rank_num,
    PERCENT_RANK() OVER (PARTITION BY region ORDER BY total_revenue DESC) AS percent_rank_num
  FROM product_revenue
)
SELECT
  region,
  product_name,
  total_revenue,
  row_num,
  rank_num,
  dense_rank_num,
  percent_rank_num
FROM ranked
WHERE row_num <= 5
ORDER BY region, row_num;

-- B2) Aggregate window functions: SUM, AVG, MIN, MAX + ROWS and RANGE frames
WITH monthly_sales AS (
  SELECT
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS [month],
    SUM(oi.quantity * oi.unit_price_at_sale) AS month_revenue
  FROM dbo.orders o
  JOIN dbo.order_items oi ON oi.order_id = o.order_id
  GROUP BY DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1)
)
SELECT
  [month],
  month_revenue,
  SUM(month_revenue) OVER (
    ORDER BY [month]
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total_rows,
  SUM(month_revenue) OVER (
    ORDER BY [month]
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total_range,
  AVG(month_revenue) OVER (
    ORDER BY [month]
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS avg_last_3_months,
  MIN(month_revenue) OVER (
    ORDER BY [month]
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS min_so_far,
  MAX(month_revenue) OVER (
    ORDER BY [month]
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS max_so_far
FROM monthly_sales
ORDER BY [month];

-- B3) Navigation functions: LAG and LEAD (period-to-period comparison)
WITH monthly_sales AS (
  SELECT
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS [month],
    SUM(oi.quantity * oi.unit_price_at_sale) AS month_revenue
  FROM dbo.orders o
  JOIN dbo.order_items oi ON oi.order_id = o.order_id
  GROUP BY DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1)
)
SELECT
  [month],
  month_revenue,
  LAG(month_revenue)  OVER (ORDER BY [month]) AS prev_month_revenue,
  LEAD(month_revenue) OVER (ORDER BY [month]) AS next_month_revenue,
  month_revenue - LAG(month_revenue) OVER (ORDER BY [month]) AS mom_change
FROM monthly_sales
ORDER BY [month];

-- B4) Distribution functions: NTILE(4) and CUME_DIST (customer segmentation)
WITH customer_spend AS (
  SELECT
    c.customer_id,
    c.full_name,
    SUM(ISNULL(oi.quantity * oi.unit_price_at_sale, 0)) AS total_spend
  FROM dbo.customers c
  LEFT JOIN dbo.orders o
    ON o.customer_id = c.customer_id
  LEFT JOIN dbo.order_items oi
    ON oi.order_id = o.order_id
  GROUP BY c.customer_id, c.full_name
)
SELECT
  customer_id,
  full_name,
  total_spend,
  NTILE(4) OVER (ORDER BY total_spend) AS spend_quartile,
  CUME_DIST() OVER (ORDER BY total_spend) AS cume_dist_value
FROM customer_spend
ORDER BY total_spend;
