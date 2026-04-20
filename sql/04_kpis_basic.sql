-- 04_kpis_basic.sql
-- Stage 1: COUNT(*) vs COUNT(column) + join-duplication bugs + safe patterns

-- 1) COUNT(*) vs COUNT(column) (NULL awareness)
-- What: count rows vs count non-null values
SELECT
  COUNT(*)                AS total_rows,
  COUNT(ship_date)      AS rows_with_ship_date,
  COUNT(DISTINCT order_id) AS distinct_orders
FROM retail.fact_sales;

-- 2) The classic join inflation bug (WRONG)
-- What: joining fact (many rows) to dim (one row per product) is safe,
-- but joining fact to fact-like tables or non-unique dims can inflate results.
-- Here we simulate an inflation by joining fact_sales to stg_superstore on order_id (many-to-many).
-- This is intentionally WRONG.
SELECT
  COUNT(*) AS inflated_rows
FROM retail.fact_sales f
JOIN retail.stg_superstore s
  ON f.order_id = s.order_id;

-- 3) Correct way: count orders without inflating (RIGHT)
-- What: count distinct order_id from fact table without extra join.
SELECT
  COUNT(DISTINCT order_id) AS order_count
FROM retail.fact_sales;

-- 4) WRONG revenue by customer (inflated) due to joining to staging on customer_id (many-to-many)
SELECT
  c.customer_id,
  SUM(f.sales) AS inflated_sales
FROM retail.fact_sales f
JOIN retail.dim_customer c ON f.customer_id = c.customer_id
JOIN retail.stg_superstore s ON s.customer_id = c.customer_id   -- WRONG join causes multiplication
GROUP BY 1
ORDER BY inflated_sales DESC
LIMIT 5;

-- 5) RIGHT revenue by customer (no inflation)
SELECT
  customer_id,
  ROUND(SUM(sales), 2) AS total_sales
FROM retail.fact_sales
GROUP BY 1
ORDER BY total_sales DESC
LIMIT 5;

-- 6) Duplicate-safe aggregation pattern: aggregate first, then join dims
WITH sales_by_customer AS (
  SELECT
    customer_id,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
  FROM retail.fact_sales
  GROUP BY 1
)
SELECT
  c.customer_name,
  c.segment,
  ROUND(s.total_sales, 2)  AS total_sales,
  ROUND(s.total_profit, 2) AS total_profit
FROM sales_by_customer s
JOIN retail.dim_customer c ON c.customer_id = s.customer_id
ORDER BY total_profit DESC
LIMIT 10;

-- 7) COUNT(DISTINCT ...) after join (safe example)
SELECT
  p.category,
  COUNT(DISTINCT f.order_id) AS distinct_orders_in_category
FROM retail.fact_sales f
JOIN retail.dim_product p ON p.product_id = f.product_id
GROUP BY 1
ORDER BY distinct_orders_in_category DESC;

-- 8) CASE WHEN: Discount bucket distribution
WITH buckets AS (
  SELECT
    CASE
      WHEN discount = 0 THEN '0%'
      WHEN discount <= 0.10 THEN '0–10%'
      WHEN discount <= 0.20 THEN '10–20%'
      WHEN discount <= 0.30 THEN '20–30%'
      ELSE '30%+'
    END AS discount_bucket,
    sales,
    profit
  FROM retail.fact_sales
)
SELECT
  discount_bucket,
  COUNT(*) AS line_items,
  ROUND(SUM(sales), 2)  AS total_sales,
  ROUND(SUM(profit), 2) AS total_profit,
  ROUND(SUM(profit) / NULLIF(SUM(sales), 0), 4) AS profit_margin
FROM buckets
GROUP BY 1
ORDER BY
  CASE discount_bucket
    WHEN '0%' THEN 1
    WHEN '0–10%' THEN 2
    WHEN '10–20%' THEN 3
    WHEN '20–30%' THEN 4
    ELSE 5
  END;

-- 9) IN: Filter to selected regions (uses dim_geo)
SELECT
  g.region,
  ROUND(SUM(f.sales), 2) AS total_sales
FROM retail.fact_sales f
JOIN retail.dim_geo g ON g.geo_id = f.geo_id
WHERE g.region IN ('West', 'East')
GROUP BY 1
ORDER BY total_sales DESC;

-- 10) BETWEEN: Orders in a date range
SELECT
  COUNT(DISTINCT order_id) AS orders_2017
FROM retail.fact_sales
WHERE order_date BETWEEN DATE '2017-01-01' AND DATE '2017-12-31';

-- 11) LIKE: Products containing a keyword
SELECT
  COUNT(*) AS chair_line_items,
  ROUND(SUM(sales), 2) AS chair_sales
FROM retail.fact_sales f
JOIN retail.dim_product p ON p.product_id = f.product_id
WHERE p.product_name ILIKE '%chair%';

-- 12) COALESCE: Safe grouping when region is missing (should be rare)
SELECT
  COALESCE(g.region, 'UNKNOWN') AS region,
  COUNT(*) AS line_items
FROM retail.fact_sales f
LEFT JOIN retail.dim_geo g ON g.geo_id = f.geo_id
GROUP BY 1
ORDER BY line_items DESC;