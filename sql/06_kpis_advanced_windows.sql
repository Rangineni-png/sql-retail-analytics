-- 06_kpis_advanced_windows.sql
-- Advanced stage: window functions (ROW_NUMBER/RANK/DENSE_RANK), LAG/LEAD, running totals, top-N per group, dedup patterns

-- 1) Monthly sales/profit + MoM growth using LAG
WITH monthly AS (
  SELECT
    DATE_TRUNC('month', order_date)::date AS month,
    SUM(sales)  AS total_sales,
    SUM(profit) AS total_profit
  FROM retail.fact_sales
  GROUP BY 1
),
with_lag AS (
  SELECT
    month,
    total_sales,
    total_profit,
    LAG(total_sales) OVER (ORDER BY month)  AS prev_sales,
    LAG(total_profit) OVER (ORDER BY month) AS prev_profit
  FROM monthly
)
SELECT
  month,
  ROUND(total_sales, 2)  AS total_sales,
  ROUND(total_profit, 2) AS total_profit,
  ROUND((total_sales - prev_sales) / NULLIF(prev_sales, 0), 4) AS mom_sales_growth,
  ROUND((total_profit - prev_profit) / NULLIF(prev_profit, 0), 4) AS mom_profit_growth
FROM with_lag
ORDER BY month;

-- 2) Running total of sales by region (PARTITION BY + running sum)
WITH region_month AS (
  SELECT
    g.region,
    DATE_TRUNC('month', f.order_date)::date AS month,
    SUM(f.sales) AS monthly_sales
  FROM retail.fact_sales f
  JOIN retail.dim_geo g ON g.geo_id = f.geo_id
  GROUP BY 1,2
)
SELECT
  region,
  month,
  ROUND(monthly_sales, 2) AS monthly_sales,
  ROUND(SUM(monthly_sales) OVER (PARTITION BY region ORDER BY month), 2) AS running_sales
FROM region_month
ORDER BY region, month;

-- 3) Top 3 products per category by profit (RANK / ROW_NUMBER)
WITH product_profit AS (
  SELECT
    p.category,
    p.product_name,
    SUM(f.profit) AS total_profit
  FROM retail.fact_sales f
  JOIN retail.dim_product p ON p.product_id = f.product_id
  GROUP BY 1,2
),
ranked AS (
  SELECT
    category,
    product_name,
    total_profit,
    RANK() OVER (PARTITION BY category ORDER BY total_profit DESC) AS rnk
  FROM product_profit
)
SELECT
  category,
  product_name,
  ROUND(total_profit, 2) AS total_profit,
  rnk
FROM ranked
WHERE rnk <= 3
ORDER BY category, rnk, total_profit DESC;

-- 4) Top 5 customers per region by profit (ROW_NUMBER top-N per group)
WITH customer_region_profit AS (
  SELECT
    g.region,
    c.customer_name,
    SUM(f.profit) AS total_profit
  FROM retail.fact_sales f
  JOIN retail.dim_geo g ON g.geo_id = f.geo_id
  JOIN retail.dim_customer c ON c.customer_id = f.customer_id
  GROUP BY 1,2
),
ranked AS (
  SELECT
    region,
    customer_name,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_profit DESC) AS rn
  FROM customer_region_profit
)
SELECT
  region,
  customer_name,
  ROUND(total_profit, 2) AS total_profit
FROM ranked
WHERE rn <= 5
ORDER BY region, total_profit DESC;

-- 5) Dedup pattern: keep the latest order per customer (ROW_NUMBER)
-- (latest by order_date, tie-break by order_id)
WITH customer_orders AS (
  SELECT
    customer_id,
    order_id,
    order_date,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY order_date DESC, order_id DESC
    ) AS rn
  FROM retail.fact_sales
)
SELECT
  customer_id,
  order_id,
  order_date
FROM customer_orders
WHERE rn = 1
ORDER BY order_date DESC
LIMIT 20;

-- 6) LEAD example: next order date per customer (gap analysis)
WITH orders AS (
  SELECT
    customer_id,
    order_id,
    order_date,
    LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_date
  FROM retail.fact_sales
)
SELECT
  customer_id,
  order_id,
  order_date,
  next_order_date,
  (next_order_date - order_date) AS days_until_next_order
FROM orders
WHERE next_order_date IS NOT NULL
ORDER BY days_until_next_order DESC
LIMIT 20;