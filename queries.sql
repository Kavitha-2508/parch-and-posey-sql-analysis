-- ============================================================
-- Parch & Posey Retail Analysis — SQL Queries
-- Database: accounts, orders, sales_reps, region, web_events
-- ============================================================

-- ===================== EDA =====================

-- Q1: How many rows are in each table?
SELECT 'web_events' AS table_name, COUNT(*) FROM web_events
UNION ALL SELECT 'sales_reps', COUNT(*) FROM sales_reps
UNION ALL SELECT 'region', COUNT(*) FROM region
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'accounts', COUNT(*) FROM accounts;

-- Q2: What is the date range of orders?
SELECT MIN(occurred_at) AS first_order, MAX(occurred_at) AS last_order
FROM orders;

-- Q3: How many of each type of paper has been sold?
SELECT SUM(standard_qty) AS standard_sold,
       SUM(gloss_qty)    AS gloss_sold,
       SUM(poster_qty)   AS poster_sold
FROM orders;

-- Q4: How much, in dollars, has each of the paper types sold?
SELECT SUM(standard_amt_usd) AS standard_usd,
       SUM(gloss_amt_usd)    AS gloss_usd,
       SUM(poster_amt_usd)   AS poster_usd
FROM orders;

-- Q5: What is the most profitable paper type?
-- Note: no cost data exists in this schema, so "profitable" is read as highest total revenue.
SELECT 'standard' AS paper_type, SUM(standard_amt_usd) AS revenue_usd FROM orders
UNION ALL SELECT 'gloss',    SUM(gloss_amt_usd)    FROM orders
UNION ALL SELECT 'poster',   SUM(poster_amt_usd)   FROM orders
ORDER BY revenue_usd DESC;

-- Q6: What are the top five accounts by average total amount?
SELECT a.name AS account_name,
       ROUND(AVG(o.total_amt_usd), 2) AS avg_order_usd
FROM orders o
JOIN accounts a ON a.id = o.account_id
GROUP BY a.name
ORDER BY avg_order_usd DESC
LIMIT 5;

-- Q7: What channel do most of the online sales come from?
SELECT channel, COUNT(*) AS event_count
FROM web_events
GROUP BY channel
ORDER BY event_count DESC;

-- Q8: Which region_id has the largest number of sales persons?
SELECT sr.region_id,
       r.name AS region_name,
       COUNT(*) AS num_sales_reps
FROM sales_reps sr
JOIN region r ON r.id = sr.region_id
GROUP BY sr.region_id, r.name
ORDER BY num_sales_reps DESC;

-- ===================== JOINS =====================

-- Q9: Which web_events channel had the highest total quantity sold of all three types of paper?
-- Caveat: web_events and orders only share account_id, not an order-level key, so joining
-- them multiplies every order by every web event for that account (many-to-many fan-out).
-- Ranking is still directionally consistent with the raw channel mix in Q7.
SELECT we.channel,
       SUM(o.standard_qty + o.gloss_qty + o.poster_qty) AS total_qty
FROM web_events we
JOIN orders o ON o.account_id = we.account_id
GROUP BY we.channel
ORDER BY total_qty DESC;

-- Q10: Which region, by name, has the highest amount of sales in USD?
SELECT r.name AS region_name,
       ROUND(SUM(o.total_amt_usd), 2) AS total_sales_usd
FROM orders o
JOIN accounts a    ON a.id = o.account_id
JOIN sales_reps sr ON sr.id = a.sales_rep_id
JOIN region r      ON r.id = sr.region_id
GROUP BY r.name
ORDER BY total_sales_usd DESC;

-- ===================== CTEs, SUBQUERIES, TEMP TABLES =====================

-- Q11: Categorize each region's average sales as "Above Average" or "Below Average"
-- vs. the company-wide average.
WITH region_avg AS (
  SELECT r.name AS region_name,
         AVG(o.total_amt_usd) AS avg_sales
  FROM orders o
  JOIN accounts a    ON a.id = o.account_id
  JOIN sales_reps sr ON sr.id = a.sales_rep_id
  JOIN region r      ON r.id = sr.region_id
  GROUP BY r.name
),
company_avg AS (
  SELECT AVG(total_amt_usd) AS avg_sales FROM orders
)
SELECT region_name,
       ROUND(avg_sales, 2) AS region_avg_sales,
       CASE WHEN avg_sales > (SELECT avg_sales FROM company_avg)
            THEN 'Above Average' ELSE 'Below Average' END AS category
FROM region_avg
ORDER BY avg_sales DESC;

-- Q12: What are the total quantities of each paper type sold for the top region?
-- "Top region" = Northeast, the highest by total USD sales from Q10.
SELECT r.name AS region_name,
       SUM(o.standard_qty) AS standard_qty,
       SUM(o.gloss_qty)    AS gloss_qty,
       SUM(o.poster_qty)   AS poster_qty
FROM orders o
JOIN accounts a    ON a.id = o.account_id
JOIN sales_reps sr ON sr.id = a.sales_rep_id
JOIN region r      ON r.id = sr.region_id
WHERE r.name = 'Northeast'
GROUP BY r.name;

-- ===================== WINDOW FUNCTIONS =====================

-- Q13: Average sales in USD by region and sales person.
-- Include region name, sales person's name, and account name. First 20 rows.
SELECT r.name  AS region_name,
       sr.name AS sales_rep_name,
       a.name  AS account_name,
       ROUND(AVG(o.total_amt_usd) OVER (PARTITION BY sr.name, r.name), 2) AS avg_sales_usd
FROM orders o
JOIN accounts a    ON a.id = o.account_id
JOIN sales_reps sr ON sr.id = a.sales_rep_id
JOIN region r      ON r.id = sr.region_id
ORDER BY avg_sales_usd DESC
LIMIT 20;

-- Q14: What is the running total of sales by month? First twenty rows.
WITH monthly_sales AS (
  SELECT DATE_TRUNC('month', occurred_at) AS order_month,
         SUM(total_amt_usd) AS month_sales
  FROM orders
  GROUP BY DATE_TRUNC('month', occurred_at)
)
SELECT order_month,
       month_sales,
       SUM(month_sales) OVER (ORDER BY order_month) AS running_total
FROM monthly_sales
ORDER BY order_month
LIMIT 20;

-- Q15: Create a seven-day moving average of orders.
-- "Orders" here means the count of orders placed per day (COUNT(*)), not dollar revenue.
WITH daily_orders AS (
  SELECT DATE(occurred_at) AS order_date,
         COUNT(*) AS daily_orders
  FROM orders
  GROUP BY DATE(occurred_at)
)
SELECT order_date,
       daily_orders,
       AVG(daily_orders) OVER (
         ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ) AS seven_day_moving_avg
FROM daily_orders
ORDER BY order_date;
