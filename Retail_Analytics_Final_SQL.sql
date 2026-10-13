/*
Retail Sales and Customer Analytics
Final MariaDB and MySQL analysis script

Dataset: UCI Online Retail II
Observation period: 2009-12-01 through 2011-12-09

Important:
- Run 01_create_tables.sql and 02_import_data.sql from the starter package first.
- This script preserves all source rows and builds analysis views.
- Exact repeated rows are flagged in the source table but retained in the main analysis.
- Costs are not available, so this project reports sales value rather than profit.
*/

USE retail_analytics;

/* --------------------------------------------------------------------------
   1. Source validation
   -------------------------------------------------------------------------- */

SELECT
    COUNT(*) AS source_rows,
    COUNT(DISTINCT invoice_no) AS source_invoices,
    MIN(invoice_date) AS first_transaction,
    MAX(invoice_date) AS last_transaction
FROM retail_analytics.retail_lines;

SELECT
    SUM(customer_id IS NULL) AS missing_customer_id_rows,
    SUM(description IS NULL OR TRIM(description) = '') AS missing_description_rows,
    SUM(is_cancellation = 1) AS cancellation_rows,
    SUM(is_exact_repeat = 1) AS exact_repeat_rows,
    SUM(quantity < 0) AS negative_quantity_rows,
    SUM(unit_price <= 0) AS nonpositive_price_rows
FROM retail_analytics.retail_lines;

/* --------------------------------------------------------------------------
   2. Positive invoice lines
   Baseline view used to identify valid positive purchase lines.
   -------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW retail_analytics.positive_invoice_lines AS
SELECT
    rl.*,
    rl.quantity * rl.unit_price AS line_value_gbp
FROM retail_analytics.retail_lines AS rl
WHERE rl.is_cancellation = 0
  AND rl.quantity > 0
  AND rl.unit_price > 0;

/* --------------------------------------------------------------------------
   3. Merchandise purchase lines
   Removes service charges, postage, adjustments, vouchers, tests and samples.
   -------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW retail_analytics.product_sales AS
SELECT pil.*
FROM retail_analytics.positive_invoice_lines AS pil
WHERE UPPER(TRIM(pil.stock_code)) NOT IN (
        'DOT', 'POST', 'C2', 'AMAZONFEE', 'BANK CHARGES',
        'B', 'ADJUST', 'ADJUST2', 'D', 'TEST001', 'TEST002',
        'M', 'S'
      )
  AND LOWER(TRIM(pil.stock_code)) NOT LIKE 'gift%';

/* --------------------------------------------------------------------------
   4. Signed merchandise transactions
   Positive purchase lines are positive; cancellation lines are negative.
   CRUK commission is excluded because it is not merchandise.
   -------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW retail_analytics.product_transactions AS
SELECT
    rl.*,
    rl.quantity * rl.unit_price AS signed_value_gbp
FROM retail_analytics.retail_lines AS rl
WHERE rl.unit_price > 0
  AND (
        (rl.is_cancellation = 0 AND rl.quantity > 0)
        OR
        (rl.is_cancellation = 1 AND rl.quantity < 0)
      )
  AND UPPER(TRIM(rl.stock_code)) NOT IN (
        'DOT', 'POST', 'C2', 'AMAZONFEE', 'BANK CHARGES',
        'CRUK', 'B', 'ADJUST', 'ADJUST2', 'D',
        'TEST001', 'TEST002', 'M', 'S'
      )
  AND LOWER(TRIM(rl.stock_code)) NOT LIKE 'gift%';

/* Reconciliation KPI: gross sales - credits = net sales. */
SELECT
    ROUND(SUM(CASE WHEN quantity > 0 THEN signed_value_gbp ELSE 0 END), 2)
        AS gross_sales_gbp,
    ROUND(SUM(CASE WHEN quantity < 0 THEN -signed_value_gbp ELSE 0 END), 2)
        AS credits_gbp,
    ROUND(SUM(signed_value_gbp), 2) AS net_sales_gbp
FROM retail_analytics.product_transactions;

/* --------------------------------------------------------------------------
   5. Monthly sales view
   December 2011 is marked as a partial month through December 9.
   -------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW retail_analytics.monthly_sales AS
SELECT
    CAST(DATE_FORMAT(invoice_date, '%Y-%m-01') AS DATE) AS sales_month,
    ROUND(SUM(CASE WHEN quantity > 0 THEN signed_value_gbp ELSE 0 END), 2)
        AS gross_sales_gbp,
    ROUND(SUM(CASE WHEN quantity < 0 THEN -signed_value_gbp ELSE 0 END), 2)
        AS credits_gbp,
    ROUND(SUM(signed_value_gbp), 2) AS net_sales_gbp,
    CASE
        WHEN DATE_FORMAT(invoice_date, '%Y-%m') = '2011-12'
            THEN 'Partial month: through Dec 9'
        ELSE 'Full month'
    END AS period_status
FROM retail_analytics.product_transactions
GROUP BY DATE_FORMAT(invoice_date, '%Y-%m');

/* --------------------------------------------------------------------------
   6. Country summary view
   Country is the shipping country recorded on the invoice line.
   -------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW retail_analytics.country_sales AS
SELECT
    country,
    ROUND(SUM(CASE WHEN quantity > 0 THEN signed_value_gbp ELSE 0 END), 2)
        AS gross_sales_gbp,
    ROUND(SUM(CASE WHEN quantity < 0 THEN -signed_value_gbp ELSE 0 END), 2)
        AS credits_gbp,
    ROUND(SUM(signed_value_gbp), 2) AS net_sales_gbp
FROM retail_analytics.product_transactions
GROUP BY country;

/* --------------------------------------------------------------------------
   7. Product summary view
   Stock code is the unique product key used in the dashboard.
   -------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW retail_analytics.product_summary AS
SELECT
    stock_code,
    MAX(TRIM(description)) AS example_description,
    SUM(quantity) AS net_units,
    ROUND(SUM(CASE WHEN quantity > 0 THEN signed_value_gbp ELSE 0 END), 2)
        AS gross_sales_gbp,
    ROUND(SUM(CASE WHEN quantity < 0 THEN -signed_value_gbp ELSE 0 END), 2)
        AS credits_gbp,
    ROUND(SUM(signed_value_gbp), 2) AS net_sales_gbp
FROM retail_analytics.product_transactions
GROUP BY stock_code;

/* --------------------------------------------------------------------------
   8. Customer RFM calculations
   Reference date is 2011-12-10, one day after the final observed transaction.
   Frequency counts distinct positive purchase invoices.
   Monetary value is net merchandise sales after credits.
   -------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW retail_analytics.customer_rfm AS
SELECT
    customer_id,
    DATEDIFF('2011-12-10', MAX(invoice_date)) AS recency_days,
    COUNT(DISTINCT invoice_no) AS frequency,
    ROUND(SUM(line_value_gbp), 2) AS monetary_gbp
FROM retail_analytics.product_sales
WHERE customer_id IS NOT NULL
GROUP BY customer_id;

CREATE OR REPLACE VIEW retail_analytics.customer_rfm_net AS
SELECT
    customer_id,
    DATEDIFF(
        '2011-12-10',
        MAX(CASE WHEN quantity > 0 THEN invoice_date END)
    ) AS recency_days,
    COUNT(DISTINCT CASE WHEN quantity > 0 THEN invoice_no END) AS frequency,
    ROUND(SUM(signed_value_gbp), 2) AS monetary_net_gbp
FROM retail_analytics.product_transactions
WHERE customer_id IS NOT NULL
GROUP BY customer_id
HAVING COUNT(DISTINCT CASE WHEN quantity > 0 THEN invoice_no END) > 0;

/* RFM score thresholds are explicit project assumptions. */
CREATE OR REPLACE VIEW retail_analytics.customer_rfm_scores AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary_net_gbp,
    CASE
        WHEN recency_days <= 30 THEN 5
        WHEN recency_days <= 90 THEN 4
        WHEN recency_days <= 180 THEN 3
        WHEN recency_days <= 365 THEN 2
        ELSE 1
    END AS r_score,
    CASE
        WHEN frequency >= 20 THEN 5
        WHEN frequency >= 10 THEN 4
        WHEN frequency >= 5 THEN 3
        WHEN frequency >= 2 THEN 2
        ELSE 1
    END AS f_score,
    CASE
        WHEN monetary_net_gbp >= 10000 THEN 5
        WHEN monetary_net_gbp >= 5000 THEN 4
        WHEN monetary_net_gbp >= 1000 THEN 3
        WHEN monetary_net_gbp >= 500 THEN 2
        ELSE 1
    END AS m_score
FROM retail_analytics.customer_rfm_net;

CREATE OR REPLACE VIEW retail_analytics.customer_segments AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary_net_gbp,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN monetary_net_gbp <= 0
            THEN 'Review net credits'
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
            THEN 'Champions'
        WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 4)
            THEN 'At risk'
        WHEN r_score >= 4 AND f_score >= 3
            THEN 'Active repeat buyers'
        WHEN r_score >= 4 AND frequency = 1
            THEN 'Recent one-time buyers'
        WHEN r_score <= 2
            THEN 'Inactive buyers'
        ELSE 'Other buyers'
    END AS customer_segment
FROM retail_analytics.customer_rfm_scores;

CREATE OR REPLACE VIEW retail_analytics.customer_segment_summary AS
SELECT
    customer_segment AS segment,
    COUNT(*) AS customer_count,
    ROUND(SUM(monetary_net_gbp), 2) AS net_sales_gbp,
    ROUND(AVG(recency_days), 1) AS avg_recency_days,
    ROUND(AVG(frequency), 1) AS avg_frequency
FROM retail_analytics.customer_segments
GROUP BY customer_segment;

/* --------------------------------------------------------------------------
   9. Dashboard export queries
   Export each result grid to CSV with the filename shown in the comment.
   -------------------------------------------------------------------------- */

/* monthly_sales.csv */
SELECT
    sales_month,
    gross_sales_gbp,
    credits_gbp,
    net_sales_gbp,
    period_status
FROM retail_analytics.monthly_sales
ORDER BY sales_month;

/* country_sales.csv */
SELECT
    country,
    gross_sales_gbp,
    credits_gbp,
    net_sales_gbp
FROM retail_analytics.country_sales
ORDER BY net_sales_gbp DESC;

/* product_summary.csv */
SELECT
    stock_code,
    example_description,
    net_units,
    gross_sales_gbp,
    credits_gbp,
    net_sales_gbp
FROM retail_analytics.product_summary
ORDER BY net_sales_gbp DESC;

/* customer_segment_summary.csv */
SELECT
    segment,
    customer_count,
    net_sales_gbp,
    avg_recency_days,
    avg_frequency
FROM retail_analytics.customer_segment_summary
ORDER BY net_sales_gbp DESC;

/* --------------------------------------------------------------------------
   10. Final validation queries and expected values
   -------------------------------------------------------------------------- */

/* Expected: 1,037,021 lines; 39,516 invoices; gross GBP 20,110,181.02. */
SELECT
    COUNT(*) AS purchase_lines,
    COUNT(DISTINCT invoice_no) AS purchase_invoices,
    ROUND(SUM(line_value_gbp), 2) AS gross_sales_gbp
FROM retail_analytics.product_sales;

/* Expected: gross 20,110,181.02; credits 726,555.99; net 19,383,625.03. */
SELECT
    ROUND(SUM(CASE WHEN quantity > 0 THEN signed_value_gbp ELSE 0 END), 2)
        AS gross_sales_gbp,
    ROUND(SUM(CASE WHEN quantity < 0 THEN -signed_value_gbp ELSE 0 END), 2)
        AS credits_gbp,
    ROUND(SUM(signed_value_gbp), 2) AS net_sales_gbp
FROM retail_analytics.product_transactions;

/* Expected: 25 monthly rows. */
SELECT COUNT(*) AS monthly_rows
FROM retail_analytics.monthly_sales;

/* Expected: 5,852 customers. */
SELECT COUNT(*) AS segmented_customers
FROM retail_analytics.customer_segments;

/* Expected segment counts sum to 5,852. */
SELECT
    segment,
    customer_count,
    net_sales_gbp,
    avg_recency_days,
    avg_frequency
FROM retail_analytics.customer_segment_summary
ORDER BY net_sales_gbp DESC;

/* Top ten products by net sales. */
SELECT
    stock_code,
    example_description,
    net_units,
    net_sales_gbp
FROM retail_analytics.product_summary
ORDER BY net_sales_gbp DESC
LIMIT 10;

/* Top countries by net sales. */
SELECT
    country,
    gross_sales_gbp,
    credits_gbp,
    net_sales_gbp
FROM retail_analytics.country_sales
ORDER BY net_sales_gbp DESC
LIMIT 10;

