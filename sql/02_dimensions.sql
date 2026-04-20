BEGIN;

-- Clean rerun
DROP TABLE IF EXISTS retail.fact_sales CASCADE;
DROP TABLE IF EXISTS retail.dim_customer CASCADE;
DROP TABLE IF EXISTS retail.dim_product CASCADE;
DROP TABLE IF EXISTS retail.dim_geo CASCADE;
DROP TABLE IF EXISTS retail.dim_date CASCADE;

-- 1) Customer dimension
CREATE TABLE retail.dim_customer AS
SELECT DISTINCT
  customer_id,
  customer_name,
  segment
FROM retail.stg_superstore
WHERE customer_id IS NOT NULL;

ALTER TABLE retail.dim_customer
  ADD PRIMARY KEY (customer_id);

-- 2) Product dimension (dedupe-safe: one row per product_id)
CREATE TABLE retail.dim_product AS
SELECT
  product_id,
  MAX(category)     AS category,
  MAX(sub_category) AS sub_category,
  MAX(product_name) AS product_name
FROM retail.stg_superstore
WHERE product_id IS NOT NULL
GROUP BY product_id;

ALTER TABLE retail.dim_product
  ADD PRIMARY KEY (product_id);

-- 3) Geography dimension (natural key = location combo)
CREATE TABLE retail.dim_geo AS
SELECT DISTINCT
  country,
  state,
  city,
  postal_code,
  region
FROM retail.stg_superstore;

-- Create a surrogate key for joins (easy + fast)
ALTER TABLE retail.dim_geo
  ADD COLUMN geo_id BIGSERIAL PRIMARY KEY;

-- Prevent duplicates if rerun logic changes later
CREATE UNIQUE INDEX IF NOT EXISTS ux_dim_geo_nk
ON retail.dim_geo (country, state, city, postal_code, region);

-- 4) Date dimension (from min to max order_date)
CREATE TABLE retail.dim_date AS
WITH bounds AS (
  SELECT
    MIN(order_date) AS min_d,
    MAX(order_date) AS max_d
  FROM retail.stg_superstore
),
dates AS (
  SELECT generate_series(
    (SELECT min_d FROM bounds),
    (SELECT max_d FROM bounds),
    interval '1 day'
  )::date AS date_day
)
SELECT
  date_day,
  EXTRACT(YEAR FROM date_day)::int  AS year,
  EXTRACT(MONTH FROM date_day)::int AS month,
  TO_CHAR(date_day, 'YYYY-MM')      AS year_month,
  EXTRACT(QUARTER FROM date_day)::int AS quarter,
  EXTRACT(DOW FROM date_day)::int     AS day_of_week
FROM dates;

ALTER TABLE retail.dim_date
  ADD PRIMARY KEY (date_day);

COMMIT;