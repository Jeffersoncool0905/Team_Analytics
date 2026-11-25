-- ==============================================================================
-- PROJECT: Financial & E-Commerce Fraud Early Detection System
-- SCRIPT 01: Staging, Schema Definitions & Production ETL Cleaning
-- DIALECT: SQLite / ANSI SQL (Compatible with PostgreSQL, MySQL, Snowflake)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- STEP 1: Flexible Staging Schema
-- Stores raw imported CSV data without type casting failures
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS stg_transactions_raw;

CREATE TABLE stg_transactions_raw (
    transaction_id          TEXT,
    trans_timestamp         TEXT,
    customer_id             TEXT,
    card_number_masked      TEXT,
    card_type               TEXT,
    customer_home_country   TEXT,
    merchant_name           TEXT,
    merchant_category       TEXT,
    merchant_country        TEXT,
    card_entry_mode         TEXT,
    device_type             TEXT,
    transaction_amount      TEXT,
    customer_avg_ticket     TEXT,
    amount_to_avg_ratio     TEXT,
    distance_km             TEXT,
    is_foreign_transaction  TEXT,
    is_fraud                TEXT,
    fraud_scenario          TEXT,
    trans_count_last_1h     TEXT
);

-- ------------------------------------------------------------------------------
-- STEP 2: Production Clean Transactions Table
-- Strict datatypes, primary key constraint, indexed time and financial metrics
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS clean_transactions;

CREATE TABLE clean_transactions (
    transaction_id          TEXT PRIMARY KEY,
    trans_timestamp         DATETIME NOT NULL,
    trans_date              DATE NOT NULL,
    trans_hour              INTEGER NOT NULL,
    trans_day_of_week       TEXT NOT NULL,
    customer_id             TEXT NOT NULL,
    card_number_masked      TEXT NOT NULL,
    card_type               TEXT NOT NULL,
    customer_home_country   TEXT NOT NULL,
    merchant_name           TEXT NOT NULL,
    merchant_category       TEXT NOT NULL,
    merchant_country        TEXT NOT NULL,
    card_entry_mode         TEXT NOT NULL,
    device_type             TEXT NOT NULL,
    transaction_amount      DECIMAL(10, 2) NOT NULL,
    customer_avg_ticket     DECIMAL(10, 2) NOT NULL,
    amount_to_avg_ratio     DECIMAL(8, 2) NOT NULL,
    distance_km             DECIMAL(10, 2) NOT NULL,
    is_foreign_transaction  INTEGER NOT NULL,
    is_fraud                INTEGER NOT NULL,
    fraud_scenario          TEXT NOT NULL,
    trans_count_last_1h     INTEGER NOT NULL,
    ticket_size_bracket     TEXT NOT NULL
);

-- ------------------------------------------------------------------------------
-- STEP 3: ETL Pipeline (Cast, Clean, Enrich & Feature Engineer)
-- Extracts temporal features and spending brackets for high-precision fraud modeling
-- ------------------------------------------------------------------------------
INSERT INTO clean_transactions (
    transaction_id,
    trans_timestamp,
    trans_date,
    trans_hour,
    trans_day_of_week,
    customer_id,
    card_number_masked,
    card_type,
    customer_home_country,
    merchant_name,
    merchant_category,
    merchant_country,
    card_entry_mode,
    device_type,
    transaction_amount,
    customer_avg_ticket,
    amount_to_avg_ratio,
    distance_km,
    is_foreign_transaction,
    is_fraud,
    fraud_scenario,
    trans_count_last_1h,
    ticket_size_bracket
)
SELECT 
    TRIM(transaction_id)                                    AS transaction_id,
    DATETIME(trans_timestamp)                              AS trans_timestamp,
    DATE(trans_timestamp)                                  AS trans_date,
    CAST(STRFTIME('%H', trans_timestamp) AS INTEGER)       AS trans_hour,
    CASE CAST(STRFTIME('%w', trans_timestamp) AS INTEGER)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END                                                     AS trans_day_of_week,
    TRIM(customer_id)                                       AS customer_id,
    TRIM(card_number_masked)                                AS card_number_masked,
    TRIM(card_type)                                         AS card_type,
    TRIM(customer_home_country)                             AS customer_home_country,
    TRIM(merchant_name)                                     AS merchant_name,
    TRIM(merchant_category)                                 AS merchant_category,
    TRIM(merchant_country)                                  AS merchant_country,
    TRIM(card_entry_mode)                                   AS card_entry_mode,
    TRIM(device_type)                                       AS device_type,
    CAST(transaction_amount AS DECIMAL(10, 2))              AS transaction_amount,
    CAST(customer_avg_ticket AS DECIMAL(10, 2))             AS customer_avg_ticket,
    CAST(amount_to_avg_ratio AS DECIMAL(8, 2))              AS amount_to_avg_ratio,
    CAST(distance_km AS DECIMAL(10, 2))                     AS distance_km,
    CAST(is_foreign_transaction AS INTEGER)                 AS is_foreign_transaction,
    CAST(is_fraud AS INTEGER)                               AS is_fraud,
    TRIM(fraud_scenario)                                    AS fraud_scenario,
    CAST(trans_count_last_1h AS INTEGER)                    AS trans_count_last_1h,
    -- Behavioral Segmentation: Ticket Size Tiers
    CASE 
        WHEN CAST(transaction_amount AS DECIMAL(10,2)) < 25.00 THEN '1. Micro (<$25)'
        WHEN CAST(transaction_amount AS DECIMAL(10,2)) < 100.00 THEN '2. Small ($25-$100)'
        WHEN CAST(transaction_amount AS DECIMAL(10,2)) < 500.00 THEN '3. Medium ($100-$500)'
        WHEN CAST(transaction_amount AS DECIMAL(10,2)) < 1500.00 THEN '4. High ($500-$1,500)'
        ELSE '5. Luxury / Critical ($1,500+)'
    END                                                     AS ticket_size_bracket
FROM stg_transactions_raw;

-- Verification Check
SELECT COUNT(*) AS total_clean_records FROM clean_transactions;
