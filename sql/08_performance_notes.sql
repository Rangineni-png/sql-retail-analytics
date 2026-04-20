-- 08_performance_notes.sql
-- Optimization layer: query shape, filtering early, avoiding duplicate inflation, EXPLAIN basics, index intuition

-- 0) Always use EXPLAIN for performance questions (does NOT execute the query)
-- What: show the plan for a common query
EXPLAIN
SELECT
  DATE_TRUNC('month', order_date)::date AS month,
  SUM(sales) AS total_sales
FROM retail.fact_sales
GROUP BY 1
ORDER BY 1;

-- 1) Filter early (better shape)
-- What: filter rows before grouping to reduce work
EXPLAIN
SELECT
  DATE_TRUNC('month', order_date)::date AS month,
  SUM(sales) AS total_sales
FROM retail.fact_sales
WHERE order_date BETWEEN DATE '2017-01-01' AND DATE '2017-12-31'
GROUP BY 1
ORDER BY 1;

-- 2) Bad shape example: join then aggregate when you don't need the join
-- What: this join adds work without adding value (we only need counts)
EXPLAIN
SELECT
  COUNT(*)
FROM retail.fact_sales f
JOIN retail.dim_product p ON p.product_id = f.product_id;

-- 3) Better shape: count directly from fact when join is unnecessary
EXPLAIN
SELECT COUNT(*)
FROM retail.fact_sales;

-- 4) Avoid duplicate inflation by aggregating before join (best practice)
-- What: aggregate to correct grain first, then join dims for labels
EXPLAIN
WITH sales_by_category AS (
  SELECT
    product_id,
    SUM(sales) AS total_sales
  FROM retail.fact_sales
  GROUP BY 1
)
SELECT
  dp.category,
  SUM(s.total_sales) AS category_sales
FROM sales_by_category s
JOIN retail.dim_product dp ON dp.product_id = s.product_id
GROUP BY 1
ORDER BY category_sales DESC;

-- 5) Index intuition: add index that matches common filter/join patterns
-- What: indexes help WHERE and JOIN predicates
-- (fact already has indexes on order_date/customer_id/product_id/geo_id, but this is a learning demo)
CREATE INDEX IF NOT EXISTS idx_fact_order_id ON retail.fact_sales(order_id);

-- 6) Check plan change after index (optional comparison)
EXPLAIN
SELECT *
FROM retail.fact_sales
WHERE order_id = 'CA-2017-152156';

-- 7) Example: using EXPLAIN ANALYZE (executes query; run only when needed)
-- Uncomment when you're comfortable:
-- EXPLAIN ANALYZE
-- SELECT
--   customer_id,
--   SUM(sales) AS total_sales
-- FROM retail.fact_sales
-- GROUP BY 1
-- ORDER BY total_sales DESC
-- LIMIT 10;