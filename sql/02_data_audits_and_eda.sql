-- ==============================================================================
-- PROJECT: Financial & E-Commerce Fraud Early Detection System
-- SCRIPT 02: Data Quality Audits & Exploratory Data Analysis (EDA)
-- DIALECT: SQLite / ANSI SQL
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- AUDIT 1: Volume, Completeness & Date Coverage
-- Verifies total population, unique cards, unique customers, and date bounds
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(*)                                AS total_transactions,
    COUNT(DISTINCT customer_id)             AS unique_customers,
    COUNT(DISTINCT card_number_masked)      AS unique_cards,
    COUNT(DISTINCT merchant_name)           AS unique_merchants,
    MIN(trans_timestamp)                    AS earliest_timestamp,
    MAX(trans_timestamp)                    AS latest_timestamp,
    ROUND(SUM(transaction_amount), 2)       AS total_volume_usd
FROM clean_transactions;

-- ------------------------------------------------------------------------------
-- AUDIT 2: Data Quality & Null Profile
-- Ensures zero missing values across critical fraud-scoring attributes
-- ------------------------------------------------------------------------------
SELECT
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END)         AS null_txn_ids,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)            AS null_cust_ids,
    SUM(CASE WHEN transaction_amount IS NULL THEN 1 ELSE 0 END)     AS null_amounts,
    SUM(CASE WHEN trans_timestamp IS NULL THEN 1 ELSE 0 END)        AS null_timestamps,
    SUM(CASE WHEN is_fraud IS NULL THEN 1 ELSE 0 END)               AS null_fraud_flags
FROM clean_transactions;

-- ------------------------------------------------------------------------------
-- AUDIT 3: Global Baseline Fraud Metrics
-- Calculates overall fraud incident rate (%) and financial loss exposure
-- ------------------------------------------------------------------------------
SELECT
    COUNT(*)                                                                AS total_transactions,
    SUM(is_fraud)                                                           AS fraud_incidents,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                              AS fraud_incidence_rate_pct,
    ROUND(SUM(transaction_amount), 2)                                      AS gross_processed_usd,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN transaction_amount ELSE 0 END), 2) AS total_fraud_loss_usd,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN transaction_amount ELSE 0 END) * 100.0 / SUM(transaction_amount), 2) AS fraud_dollar_loss_pct
FROM clean_transactions;

-- ------------------------------------------------------------------------------
-- AUDIT 4: Fraud Concentration by Merchant Category
-- Identifies top business sectors targeted by fraudsters
-- ------------------------------------------------------------------------------
SELECT
    merchant_category,
    COUNT(*)                                                                AS total_txns,
    SUM(is_fraud)                                                           AS fraud_txns,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                              AS category_fraud_rate_pct,
    ROUND(SUM(transaction_amount), 2)                                      AS total_spend_usd,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN transaction_amount ELSE 0 END), 2) AS fraud_loss_usd,
    ROUND(AVG(transaction_amount), 2)                                       AS avg_ticket_usd
FROM clean_transactions
GROUP BY merchant_category
ORDER BY fraud_loss_usd DESC;

-- ------------------------------------------------------------------------------
-- AUDIT 5: Vulnerability Breakdown by Card Entry Mode & Device Type
-- Evaluates risk differences between Online (CNP) vs In-Store (Chip/Swipe/NFC)
-- ------------------------------------------------------------------------------
SELECT
    card_entry_mode,
    device_type,
    COUNT(*)                                                                AS total_txns,
    SUM(is_fraud)                                                           AS fraud_txns,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                              AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN transaction_amount ELSE 0 END), 2) AS total_loss_usd
FROM clean_transactions
GROUP BY card_entry_mode, device_type
ORDER BY fraud_rate_pct DESC;

-- ------------------------------------------------------------------------------
-- AUDIT 6: Cross-Border & Foreign Transaction Risk
-- Measures exposure to foreign vs domestic transaction flows
-- ------------------------------------------------------------------------------
SELECT
    CASE WHEN is_foreign_transaction = 1 THEN 'Foreign / Cross-Border' ELSE 'Domestic' END AS transaction_scope,
    COUNT(*)                                                                AS total_txns,
    SUM(is_fraud)                                                           AS fraud_txns,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                              AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN transaction_amount ELSE 0 END), 2) AS fraud_loss_usd
FROM clean_transactions
GROUP BY is_foreign_transaction;
