# 🤖 Phase 3: Machine Learning Fraud Classification
### Assigned to: Machine Learning Engineer

## 🎯 Objective
Train supervised fraud detection models (`train_fraud_model.py`) using Scikit-Learn or XGBoost to predict the probability of transaction fraud.

## 📋 Recommended Specifications
* **Class Imbalance Handling:** Baseline fraud rate is 3.33% (333 fraud vs 9,667 legitimate). Use `BalancedRandomForestClassifier`, `class_weight='balanced'`, or SMOTE.
* **Evaluation Metrics:** Prioritize **PR-AUC (Precision-Recall Curve)**, Recall @ 95% Precision, and ROC-AUC over basic accuracy.
* **Feature Importance:** Extract MDI (Mean Decrease in Impurity) or SHAP values to identify key risk drivers.
* **Scored Output:** Generate a scored dataset containing `fraud_probability` (0.00 to 1.00) and risk tier assignments (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`).

## 🔗 Data Source
Query directly from `../fraud_detection.db` (`clean_transactions` table) or `../data/transactions_raw.csv`.
