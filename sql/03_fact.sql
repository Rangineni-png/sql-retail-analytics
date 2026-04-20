BEGIN;

DROP TABLE IF EXISTS retail.fact_sales;

CREATE TABLE retail.fact_sales AS
SELECT
  s.row_id,
  s.order_id,
  s.order_date,
  s.ship_date,
  s.ship_mode,

  s.customer_id,
  s.product_id,
  g.geo_id,

  s.sales,
  s.quantity,
  s.discount,
  s.profit
FROM retail.stg_superstore s
JOIN retail.dim_geo g
  ON s.country = g.country
 AND s.state = g.state
 AND s.city = g.city
 AND COALESCE(s.postal_code, '') = COALESCE(g.postal_code, '')
 AND s.region = g.region;

-- Constraints / indexes (light but useful)
ALTER TABLE retail.fact_sales
  ADD PRIMARY KEY (row_id);

ALTER TABLE retail.fact_sales
  ADD CONSTRAINT fk_fact_customer FOREIGN KEY (customer_id) REFERENCES retail.dim_customer(customer_id);

ALTER TABLE retail.fact_sales
  ADD CONSTRAINT fk_fact_product FOREIGN KEY (product_id) REFERENCES retail.dim_product(product_id);

ALTER TABLE retail.fact_sales
  ADD CONSTRAINT fk_fact_date FOREIGN KEY (order_date) REFERENCES retail.dim_date(date_day);

ALTER TABLE retail.fact_sales
  ADD CONSTRAINT fk_fact_geo FOREIGN KEY (geo_id) REFERENCES retail.dim_geo(geo_id);

CREATE INDEX IF NOT EXISTS idx_fact_order_date ON retail.fact_sales(order_date);
CREATE INDEX IF NOT EXISTS idx_fact_customer   ON retail.fact_sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_fact_product    ON retail.fact_sales(product_id);
CREATE INDEX IF NOT EXISTS idx_fact_geo        ON retail.fact_sales(geo_id);

COMMIT;