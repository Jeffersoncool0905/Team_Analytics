# 📊 Phase 2: Excel Financial & Rule Tradeoff Simulator
### Assigned to: Excel Financial Modeler

## 🎯 Objective
Build an executive-ready financial simulation workbook (`Fraud_Rules_Tradeoff_Model.xlsx`) to model the business tradeoff between **Fraud Loss Exposure** (Chargebacks) and **Customer Friction** (False Declines).

## 📋 Suggested Sheet Structure
1. `Executive_Summary`:
   - High-level KPIs: Total Processed (\$1.55M), Baseline Fraud Rate (3.33%), Gross Fraud Dollar Loss (\$481,257.67).
   - Scenario comparison table (Baseline vs. Rules vs. ML vs. Hybrid).
2. `Rule_Simulator`:
   - Dynamic threshold inputs (Ticket bracket, Velocity count, Amount-to-Avg ratio).
   - Dynamic calculations of True Positives, False Positives, False Negatives, and Net Financial Savings.
3. `Scored_Data_Sample`:
   - Sample transactions linked to dynamic rules with automated conditional formatting flags.

## 🔗 Data Source
Read directly from `../data/transactions_raw.csv` or connect to `../fraud_detection.db` using ODBC / SQLite.
