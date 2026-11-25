-- ==============================================================================
-- PROJECT: Financial & E-Commerce Fraud Early Detection System
-- SCRIPT 03: Advanced Fraud Analytics, Window Functions & Real-Time Alert Queue
-- DIALECT: SQLite / ANSI SQL
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. TICKET SIZE FRAUD CONCENTRATION
-- Exposes bimodal fraud: Micro card-testing ($0-$25) vs Luxury bust-outs ($1,500+)
-- ------------------------------------------------------------------------------
SELECT
    ticket_size_bracket,
    COUNT(*)                                                                AS total_transactions,
    SUM(is_fraud)                                                           AS fraud_cases,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                              AS fraud_rate_pct,
    ROUND(SUM(transaction_amount), 2)                                      AS total_volume_dollars,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN transaction_amount ELSE 0 END), 2) AS fraud_loss_dollars
FROM clean_transactions
GROUP BY ticket_size_bracket
ORDER BY ticket_size_bracket;

-- ------------------------------------------------------------------------------
-- 2. "IMPOSSIBLE TRAVEL" VELOCITY DETECTION (Window Function: LAG)
-- Identifies physically impossible multi-country hops (>800 km/h)
-- ------------------------------------------------------------------------------
WITH consecutive_swipes AS (
    SELECT
        transaction_id,
        customer_id,
        trans_timestamp,
        merchant_country,
        distance_km,
        transaction_amount,
        is_fraud,
        -- Previous transaction details partitioned by customer
        LAG(trans_timestamp) OVER (
            PARTITION BY customer_id 
            ORDER BY trans_timestamp
        ) AS prev_timestamp,
        LAG(merchant_country) OVER (
            PARTITION BY customer_id 
            ORDER BY trans_timestamp
        ) AS prev_country,
        LAG(distance_km) OVER (
            PARTITION BY customer_id 
            ORDER BY trans_timestamp
        ) AS prev_distance_km
    FROM clean_transactions
),
speed_analysis AS (
    SELECT
        transaction_id,
        customer_id,
        prev_country || ' -> ' || merchant_country AS travel_route,
        ROUND(ABS(distance_km - prev_distance_km), 2) AS distance_difference_km,
        ROUND((JULIANDAY(trans_timestamp) - JULIANDAY(prev_timestamp)) * 24.0, 4) AS elapsed_hours,
        -- Speed in km/h = distance delta / elapsed time
        ROUND(
            ABS(distance_km - prev_distance_km) / 
            NULLIF((JULIANDAY(trans_timestamp) - JULIANDAY(prev_timestamp)) * 24.0, 0), 
            2
        ) AS speed_kmh,
        transaction_amount,
        is_fraud
    FROM consecutive_swipes
    WHERE prev_timestamp IS NOT NULL
      AND prev_country <> merchant_country
)
SELECT
    transaction_id,
    customer_id,
    travel_route,
    distance_difference_km,
    elapsed_hours,
    speed_kmh,
    CASE 
        WHEN speed_kmh > 800.0 THEN '🚨 ALERT: Impossible Travel (>800 km/h)'
        ELSE 'Normal Travel Speed'
    END AS travel_alert,
    is_fraud
FROM speed_analysis
WHERE speed_kmh > 800.0
ORDER BY speed_kmh DESC;

-- ------------------------------------------------------------------------------
-- 3. DIURNAL ATTACK PATTERN (24-Hour Attack Cycle)
-- Identifies peak attack windows (Midnight to 5 AM off-hours targeting)
-- ------------------------------------------------------------------------------
SELECT
    trans_hour,
    CASE 
        WHEN trans_hour BETWEEN 0 AND 5 THEN '1. Late Night / Early Morning (12 AM - 5 AM)'
        WHEN trans_hour BETWEEN 6 AND 11 THEN '2. Morning (6 AM - 11 AM)'
        WHEN trans_hour BETWEEN 12 AND 17 THEN '3. Afternoon (12 PM - 5 PM)'
        ELSE '4. Evening (6 PM - 11 PM)'
    END AS time_period,
    COUNT(*)                                                                AS total_transactions,
    SUM(is_fraud)                                                           AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                              AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN transaction_amount ELSE 0 END), 2) AS fraud_dollar_loss
FROM clean_transactions
GROUP BY trans_hour
ORDER BY trans_hour;

-- ------------------------------------------------------------------------------
-- 4. REAL-TIME FRAUD ALERT TRIAGE QUEUE (View Creation)
-- Uses DENSE_RANK() to dynamically prioritize cases by financial loss risk
-- ------------------------------------------------------------------------------
DROP VIEW IF EXISTS v_fraud_alert_queue;

CREATE VIEW v_fraud_alert_queue AS
SELECT
    DENSE_RANK() OVER (ORDER BY transaction_amount DESC) AS triage_priority_rank,
    transaction_id,
    trans_timestamp,
    trans_day_of_week,
    trans_hour,
    customer_id,
    card_number_masked,
    card_type,
    merchant_name,
    merchant_category,
    merchant_country,
    card_entry_mode,
    transaction_amount,
    customer_avg_ticket,
    amount_to_avg_ratio,
    distance_km,
    is_foreign_transaction,
    trans_count_last_1h,
    ticket_size_bracket,
    fraud_scenario,
    is_fraud
FROM clean_transactions
WHERE is_fraud = 1
   OR amount_to_avg_ratio > 3.0
   OR trans_count_last_1h >= 4;

-- ------------------------------------------------------------------------------
-- 5. TRIAGE QUEUE INSPECTION (Top 15 High-Exposure Cases)
-- ------------------------------------------------------------------------------
SELECT 
    triage_priority_rank,
    transaction_id,
    customer_id,
    merchant_name,
    merchant_category,
    card_entry_mode,
    transaction_amount,
    fraud_scenario
FROM v_fraud_alert_queue
WHERE triage_priority_rank <= 15
ORDER BY triage_priority_rank;
