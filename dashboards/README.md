# 📈 Phase 4: Power BI & Tableau Executive Dashboards
### Assigned to: Business Intelligence Lead

## 🎯 Objective
Design enterprise-grade executive and operational fraud monitoring dashboards in **Power BI** (`.pbix`) and/or **Tableau** (`.twbx`).

## 📋 Recommended Specifications
* **Data Model:** Star Schema dimensional architecture (`Dim_Customer`, `Dim_Merchant`, `Dim_Date`, `Fact_Transactions`).
* **Core DAX / Calculated Fields:**
  - `[Total Processed Volume]`
  - `[Total Fraud Losses]`
  - `[Prevented Fraud Loss]`
  - `[False Positive Rate]`
  - `[Rolling 7-Day Fraud Incident Rate]`
* **Key Visuals:**
  - Executive KPI Cards (Loss Prevention %, Net Chargeback Exposure)
  - Diurnal Heatmap (Transaction Hour vs. Day of Week)
  - Geospatial Attack Map (Impossible travel routes & cross-border risk)
  - Live Fraud Operations Triage Queue table linked to `v_fraud_alert_queue`

## 🔗 Data Source
Connect via SQLite ODBC or import the cleaned data from `../fraud_detection.db`.
