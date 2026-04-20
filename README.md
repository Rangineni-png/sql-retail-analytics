# SQL Retail Analytics Project (PostgreSQL)

A SQL-only GitHub project built on a Superstore retail dataset to practice SQL from intermediate to advanced:
- duplicate-safe aggregation after joins
- CASE / COALESCE / IN / BETWEEN / LIKE
- subqueries, correlated subqueries, EXISTS, CTEs
- window functions (ROW_NUMBER/RANK/LAG/LEAD), running totals
- optimization thinking using EXPLAIN and index intuition
- data quality checks

## Tech
PostgreSQL + psql

## Project Model
- `retail.stg_superstore` (staging / raw landing)
- `retail.dim_customer`, `retail.dim_product`, `retail.dim_geo`, `retail.dim_date`
- `retail.fact_sales` (one row per order line)

## How to Run (psql)
1) Create DB + schema
```bash
createdb -U postgres retail_analytics
psql -U postgres -d retail_analytics -f sql/00_setup.sql