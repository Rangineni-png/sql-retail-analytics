# SQL Retail Analytics (PostgreSQL)

A SQL-only portfolio project using PostgreSQL + `psql` to build a small analytics warehouse and practice **intermediate → advanced SQL** on a retail dataset (Superstore).

This repo demonstrates:
- Star schema modeling (staging → dimensions → fact)
- Duplicate-safe aggregation after joins (common real-world bug)
- CASE / COALESCE / IN / BETWEEN / LIKE
- Subqueries, correlated subqueries, EXISTS, CTEs
- Window functions (ROW_NUMBER / RANK / LAG / LEAD), running totals, top-N per group
- Data quality checks
- Optimization thinking with `EXPLAIN` + index intuition

---

## Tech
- PostgreSQL (local)
- `psql` CLI
- Git/GitHub

---

## Warehouse Model (Star Schema)

- **Staging:** `retail.stg_superstore` (raw landing table)
- **Dimensions:** `retail.dim_customer`, `retail.dim_product`, `retail.dim_geo`, `retail.dim_date`
- **Fact:** `retail.fact_sales` (1 row per order line item)

---

## Repo Layout

- `sql/00_setup.sql` – schema setup
- `sql/01_staging.sql` – staging table DDL
- `sql/02_dimensions.sql` – build dimensions (safe rerun; drops fact first)
- `sql/03_fact.sql` – build fact + FKs + indexes
- `sql/04_kpis_basic.sql` – join inflation + CASE/COALESCE/filters
- `sql/05_kpis_intermediate.sql` – subqueries, EXISTS, CTEs, self-joins, UNION ALL
- `sql/06_kpis_advanced_windows.sql` – window functions (LAG/LEAD, running totals, top-N)
- `sql/07_data_quality.sql` – row counts, uniqueness, FK checks, sanity checks
- `sql/08_performance_notes.sql` – EXPLAIN + query shape + index intuition
- `results/screenshots/` – proof of execution

---

## Expected Outputs (sanity)
- `retail.fact_sales` row count: **9994**
- `retail.dim_date` row count: **1458**
- Orders: `COUNT(DISTINCT order_id)` = **5009**
- Data quality checks: 0 duplicates, 0 missing FKs

---

# Quick Verify Run (recommended)

Use this if the database and tables already exist and you just want to confirm everything works.

```bash
psql -U postgres -d retail_analytics -c "SELECT COUNT(*) FROM retail.fact_sales;"
psql -U postgres -d retail_analytics -f sql/07_data_quality.sql
psql -U postgres -d retail_analytics -f sql/06_kpis_advanced_windows.sql
psql -U postgres -d retail_analytics -c "EXPLAIN SELECT DATE_TRUNC('month', order_date)::date AS month, SUM(sales) AS total_sales FROM retail.fact_sales WHERE order_date BETWEEN DATE '2017-01-01' AND DATE '2017-12-31' GROUP BY 1 ORDER BY 1;"