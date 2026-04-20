# Results / Proof of Execution

This folder contains screenshots proving the SQL pipeline ran successfully in PostgreSQL.

## What each screenshot proves

### 1) `postgres_fact_sales_count.png`
**What it shows:** `SELECT COUNT(*) FROM retail.fact_sales;`  
**Why it matters:** Confirms the warehouse model produced the expected fact table row count (**9994**). This is the core “data landed correctly” check.

### 2) `postgres_discount_buckets.png`
**What it shows:** Discount bucket analysis (CASE + GROUP BY + aggregation).  
**Why it matters:** Demonstrates correct use of `CASE WHEN`, aggregation, and safe metric computation (profit margin).

### 3) `postgres_mom_growth.png`
**What it shows:** Month-over-month metrics using window functions (`LAG`) and growth calculations.  
**Why it matters:** Demonstrates advanced SQL skills: time-series analytics + window functions.

### 4) `postgres_explain_plan.png`
**What it shows:** `EXPLAIN` plan for a filtered monthly aggregation query.  
**Why it matters:** Demonstrates optimization thinking (filter early, index usage, query plan awareness).

## Suggested verification queries (quick)
If you want to validate quickly without rebuilding:

```sql
SELECT COUNT(*) FROM retail.fact_sales;
SELECT COUNT(DISTINCT order_id) FROM retail.fact_sales;
SELECT MIN(order_date), MAX(order_date) FROM retail.fact_sales;