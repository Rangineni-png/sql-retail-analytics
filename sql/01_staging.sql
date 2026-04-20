BEGIN;

DROP TABLE IF EXISTS retail.stg_superstore;

CREATE TABLE retail.stg_superstore (
  row_id        INT,
  order_id      TEXT,
  order_date    DATE,
  ship_date     DATE,
  ship_mode     TEXT,
  customer_id   TEXT,
  customer_name TEXT,
  segment       TEXT,
  country       TEXT,
  city          TEXT,
  state         TEXT,
  postal_code   TEXT,
  region        TEXT,
  product_id    TEXT,
  category      TEXT,
  sub_category  TEXT,
  product_name  TEXT,
  sales         NUMERIC(12,2),
  quantity      INT,
  discount      NUMERIC(6,4),
  profit        NUMERIC(12,2)
);

COMMIT;