# plsql_window_functions_22967_Rubagumya

NAME: RUBAGUMYA Alain
STUDENT ID: 22967
COURSE NAME: PL/SQL

SCENARIO: ElectroStore Annual Performance

STEP 1: Business Problem:

For ElectroStore, a consumer electronics retailer, the annual sales data needs to be reviewed by the Sales and Marketing team. 
This analysis will take into account customer behavior patterns, product performance, and pricing distribution.

Data Challenge.
There are several tables that contain data on sales. 
It's not possible to identify trends, compare performance,
and support management decisions without the use of SQL 
JOINs and window functions.

Expected Outcome.
The goal is to create useful business intelligence through
the use of SQL JOINs and window functions.

STEP 2: SUCCESS Criteria:
#1. Identify top 5 products per region using RANK().
#2. Compute running monthly sales totals using SUM() OVER().
#3. Measure month-over-month revenue changes using LAG().
#4. Segment customers into spending quartiles using NTIL(4).
#5. Calculate three-month moving averages using AVG() OVER().

STEP 3 Databases SCHEMA:

TABLES:
#1. customers
#2. Products
#3. orders
#4. order_items

Relationships:

#- One customer Places many orders.
#- One order contains many order items.
#- One product appears in many order items.

ER DIAGRAM:

![alt text](<ScreenShots/ER Diagrams.png>)

STEP 4: Part A — SQL JOINs Implementation (All required JOIN types)


SQL JOINS 

INNER JOIN Query:
--=============--

SELECT o.order_id, o.order_date, c.full_name, p.product_name, oi.quantity,
       oi.unit_price_at_sale, (oi.quantity * oi.unit_price_at_sale) AS line_total
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id;

![alt text](<ScreenShots/PART A INNER JOIN.png>)

LEFT JOIN Query:
--===========--

SELECT c.customer_id, c.full_name, c.region
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

![alt text](<ScreenShots/PART A LEFT JOIN.png>)

SELF JOIN Query:
--=============--

SELECT c1.region, c1.full_name AS customer_a, c2.full_name AS customer_b
FROM customers c1
JOIN customers c2 
  ON c1.region = c2.region 
 AND c1.customer_id < c2.customer_id;

![alt text](<ScreenShots/SELF JOIN.png>)

FULL OUTER JOIN Query
--=================--

WITH customer_activity AS (
  SELECT DISTINCT c.customer_id, c.full_name
  FROM customers c
  LEFT JOIN orders o 
    ON o.customer_id = c.customer_id
),
product_activity AS (
  SELECT DISTINCT p.product_id, p.product_name
  FROM products p
  LEFT JOIN order_items oi 
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

![alt text](<ScreenShots/FULL OUTER JOIN.png>)

STEP 5: Part B — Window Functions Implementation (4 categories)

1. Ranking Functions ROW_NUMBER(), RANK(), DENSE_RANK(), PERCENT_RANK():
--==========================================================--

WITH product_revenue AS (
  SELECT
    o.region,
    p.product_name,
    SUM(oi.quantity * oi.unit_price_at_sale) AS total_revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  GROUP BY o.region, p.product_name
)
SELECT
  region,
  product_name,
  total_revenue,
  ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_revenue DESC) AS row_num,
  RANK() OVER (PARTITION BY region ORDER BY total_revenue DESC) AS rank_num,
  DENSE_RANK() OVER (PARTITION BY region ORDER BY total_revenue DESC) AS dense_rank_num,
  PERCENT_RANK() OVER (PARTITION BY region ORDER BY total_revenue DESC) AS percent_rank_num
FROM product_revenue
ORDER BY region, total_revenue DESC;

![alt text](<ScreenShots/RANK () FUNCTION.png>)


2. Aggregate Window Functions SUM(), AVG(), MIN(), MAX() 
--======================================================--

WITH monthly_sales AS (
  SELECT
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS [month],
    SUM(oi.quantity * oi.unit_price_at_sale) AS month_revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
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

![alt text](<ScreenShots/AVG() OVER().png>)


 Navigation Functions LAG(), LEAD():
--=======================================--
 WITH monthly_sales AS (
  SELECT
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS [month],
    SUM(oi.quantity * oi.unit_price_at_sale) AS month_revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1)
)
SELECT
  [month],
  month_revenue,
  LAG(month_revenue) OVER (ORDER BY [month]) AS previous_month,
  LEAD(month_revenue) OVER (ORDER BY [month]) AS next_month,
  month_revenue - LAG(month_revenue) OVER (ORDER BY [month]) AS month_difference
FROM monthly_sales
ORDER BY [month];

![alt text](<ScreenShots/LAG().png>)

Distribution Functions NTILE(4), CUME_DIST():
--===============================================--

WITH customer_spend AS (
  SELECT
    c.customer_id,
    c.full_name,
    SUM(ISNULL(oi.quantity * oi.unit_price_at_sale, 0)) AS total_spend
  FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.customer_id
  LEFT JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY c.customer_id, c.full_name
)
SELECT
  customer_id,
  full_name,
  total_spend,
  NTILE(4) OVER (ORDER BY total_spend) AS spend_quartile,
  CUME_DIST() OVER (ORDER BY total_spend) AS cumulative_distribution
FROM customer_spend
ORDER BY total_spend;

![alt text](<ScreenShots/CUSTOMER GROUPED NTILE.png>)

STEP 6: GITHUB REPOSITORY

Repository name: https://github.com/RubagumyaAlain/plsql_window_functions_22967_Rubagumya
Visibility: Public

STEP 7: RESULTS ANALYSIS

Descriptive (What happened?)

A small number of products generated the most revenue, although sales varied by month and location.
While some consumers registered but made no purchases, others made multiple purchases.

Diagnostic (Why did it happen?)

Popular categories and areas with higher purchasing power were the main drivers of high
performance. Products with low sales may be overpriced, badly marketed, or not in line with
consumer preferences. Customers who don't place orders might not be aware of promotions, have no
incentives, or lack trust.

Prescriptive (What should be done next?)

Run targeted promotions for underperforming regions and increase stock and marketing attention on
the top-ranked products by region. Make onboarding campaigns for clients who haven't placed any
orders yet. Examine unsold items for removal, bundling, or discounting.

STEP 8: REFERENCES

Microsoft Learn. In SQL Server, the OVER() clause and SELECT – JOINs are both present.
Https://learn.microsoft.com/en-us/sql/t-sql/queries/select-over-clause-transact-sql.

Microsoft Learn. Analytic queries and window functions in SQL Server.
Https://learn.microsoft.com/en-us/sql/t-sql/functions/window-functions-transact-sql.

PostgreSQL Documentation. Window functions tutorial.
Https://www.postgresql.org/docs/current/tutorial-window.html.

W3Schools. SQL JOINs and Window Functions.
Https://www.w3schools.com/sql/

"All sources were properly cited. Implementations and analysis represent original work. No AI
generated content was copied without attribution or adaptation."
