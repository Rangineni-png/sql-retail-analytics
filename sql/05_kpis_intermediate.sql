-- 05_kpis_intermediate.sql
-- Intermediate stage: subqueries, correlated subqueries, EXISTS, CTEs, self joins, UNION ALL

-- 1) Subquery: customers whose total profit is above average customer profit
-- What: compute profit per customer, then compare to the average of those profits
WITH profit_by_customer AS (
  SELECT customer_id, SUM(profit) AS total_profit
  FROM retail.fact_sales
  GROUP BY 1
),
avg_profit AS (
  SELECT AVG(total_profit) AS avg_customer_profit
  FROM profit_by_customer
)
SELECT
  p.customer_id,
  ROUND(p.total_profit, 2) AS total_profit
FROM profit_by_customer p
CROSS JOIN avg_profit a
WHERE p.total_profit > a.avg_customer_profit
ORDER BY p.total_profit DESC
LIMIT 10;

-- 2) Correlated subquery: top profitable product within each category (one per category)
-- What: for each product row, keep it if its profit equals the max profit in its category
WITH product_profit AS (
  SELECT
    p.category,
    p.product_id,
    p.product_name,
    SUM(f.profit) AS total_profit
  FROM retail.fact_sales f
  JOIN retail.dim_product p ON p.product_id = f.product_id
  GROUP BY 1,2,3
)
SELECT
  pp.category,
  pp.product_name,
  ROUND(pp.total_profit, 2) AS total_profit
FROM product_profit pp
WHERE pp.total_profit = (
  SELECT MAX(pp2.total_profit)
  FROM product_profit pp2
  WHERE pp2.category = pp.category
)
ORDER BY pp.category;

-- 3) EXISTS: customers who have ever bought from Technology category
-- What: use EXISTS to test presence of at least one matching row
SELECT
  c.customer_id,
  c.customer_name,
  c.segment
FROM retail.dim_customer c
WHERE EXISTS (
  SELECT 1
  FROM retail.fact_sales f
  JOIN retail.dim_product p ON p.product_id = f.product_id
  WHERE f.customer_id = c.customer_id
    AND p.category = 'Technology'
)
ORDER BY c.customer_id
LIMIT 10;

-- 4) IN vs EXISTS (same question using IN)
-- What: IN works but can be slower/less flexible than EXISTS in some cases
SELECT
  customer_id
FROM retail.dim_customer
WHERE customer_id IN (
  SELECT DISTINCT f.customer_id
  FROM retail.fact_sales f
  JOIN retail.dim_product p ON p.product_id = f.product_id
  WHERE p.category = 'Technology'
)
ORDER BY customer_id
LIMIT 10;

-- 5) CTE pipeline: New vs Returning customers by month
-- What: first order date per customer, then classify each order month
WITH first_order AS (
  SELECT
    customer_id,
    MIN(order_date) AS first_order_date
  FROM retail.fact_sales
  GROUP BY 1
),
orders_by_month AS (
  SELECT
    DATE_TRUNC('month', f.order_date)::date AS month,
    f.customer_id,
    fo.first_order_date
  FROM retail.fact_sales f
  JOIN first_order fo ON fo.customer_id = f.customer_id
),
classified AS (
  SELECT
    month,
    customer_id,
    CASE
      WHEN DATE_TRUNC('month', first_order_date)::date = month THEN 'new'
      ELSE 'returning'
    END AS customer_type
  FROM orders_by_month
)
SELECT
  month,
  customer_type,
  COUNT(DISTINCT customer_id) AS customers
FROM classified
GROUP BY 1,2
ORDER BY 1,2;

-- 6) Self join: find customers in the same city (pairs)
-- What: self-join dim_customer via fact+geo to make customer pairs in same city
WITH customer_city AS (
  SELECT DISTINCT
    f.customer_id,
    g.city,
    g.state
  FROM retail.fact_sales f
  JOIN retail.dim_geo g ON g.geo_id = f.geo_id
)
SELECT
  a.city,
  a.state,
  a.customer_id AS customer_a,
  b.customer_id AS customer_b
FROM customer_city a
JOIN customer_city b
  ON a.city = b.city
 AND a.state = b.state
 AND a.customer_id < b.customer_id
ORDER BY a.city, a.state
LIMIT 20;

-- 7) UNION ALL: combine two segments into one result set with labels
-- What: show top 5 customers by profit for Consumer and Corporate separately, then union together
WITH customer_profit AS (
  SELECT
    c.segment,
    c.customer_name,
    SUM(f.profit) AS total_profit
  FROM retail.fact_sales f
  JOIN retail.dim_customer c ON c.customer_id = f.customer_id
  GROUP BY 1,2
),
ranked AS (
  SELECT
    segment,
    customer_name,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY segment ORDER BY total_profit DESC) AS rn
  FROM customer_profit
)
SELECT segment, customer_name, ROUND(total_profit,2) AS total_profit
FROM ranked
WHERE segment = 'Consumer' AND rn <= 5

UNION ALL

SELECT segment, customer_name, ROUND(total_profit,2) AS total_profit
FROM ranked
WHERE segment = 'Corporate' AND rn <= 5
ORDER BY segment, total_profit DESC;