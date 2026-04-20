-- 07_data_quality.sql
-- Data quality checks for the model (staging -> dims -> fact)
-- Goal: prove the pipeline is consistent and joins won't silently corrupt metrics

-- 1) Row counts: staging vs fact should match (same grain: one row per line item)
SELECT
  (SELECT COUNT(*) FROM retail.stg_superstore) AS stg_rows,
  (SELECT COUNT(*) FROM retail.fact_sales)    AS fact_rows;

-- 2) Uniqueness: row_id should be unique in staging and fact
SELECT
  (SELECT COUNT(*) FROM retail.stg_superstore) - (SELECT COUNT(DISTINCT row_id) FROM retail.stg_superstore)
    AS stg_duplicate_row_id,
  (SELECT COUNT(*) FROM retail.fact_sales) - (SELECT COUNT(DISTINCT row_id) FROM retail.fact_sales)
    AS fact_duplicate_row_id;

-- 3) NULL checks (keys and required fields)
SELECT
  COUNT(*) FILTER (WHERE order_id IS NULL)    AS null_order_id,
  COUNT(*) FILTER (WHERE order_date IS NULL)  AS null_order_date,
  COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
  COUNT(*) FILTER (WHERE product_id IS NULL)  AS null_product_id
FROM retail.fact_sales;

-- 4) FK integrity checks (should be 0 for all if model is consistent)
SELECT
  COUNT(*) FILTER (WHERE c.customer_id IS NULL) AS missing_customer_fk,
  COUNT(*) FILTER (WHERE p.product_id IS NULL)  AS missing_product_fk,
  COUNT(*) FILTER (WHERE d.date_day IS NULL)    AS missing_date_fk,
  COUNT(*) FILTER (WHERE g.geo_id IS NULL)      AS missing_geo_fk
FROM retail.fact_sales f
LEFT JOIN retail.dim_customer c ON c.customer_id = f.customer_id
LEFT JOIN retail.dim_product  p ON p.product_id  = f.product_id
LEFT JOIN retail.dim_date     d ON d.date_day    = f.order_date
LEFT JOIN retail.dim_geo      g ON g.geo_id      = f.geo_id;

-- 5) Numeric sanity checks (should be 0 rows ideally)
SELECT
  COUNT(*) FILTER (WHERE sales < 0)                    AS negative_sales_rows,
  COUNT(*) FILTER (WHERE quantity < 0)                 AS negative_quantity_rows,
  COUNT(*) FILTER (WHERE discount < 0 OR discount > 1) AS invalid_discount_rows
FROM retail.fact_sales;

-- 6) Date sanity check: ship_date should not be before order_date
SELECT
  COUNT(*) AS ship_before_order_rows
FROM retail.fact_sales
WHERE ship_date IS NOT NULL
  AND ship_date < order_date;