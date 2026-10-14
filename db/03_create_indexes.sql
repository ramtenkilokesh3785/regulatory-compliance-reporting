-- ============================================================================
-- Script 03: Create Indexes for Regulatory Compliance Reporting Performance
-- Database: compliance_db
-- Target Engine: MySQL 8.0.46
-- ============================================================================

USE `compliance_db`;

-- Indexes for transaction extraction and aggregate queries
CREATE INDEX `idx_flags_status_flagged_txn` 
  ON `transaction_flags` (`review_status`, `flagged_at`, `transaction_id`);

CREATE INDEX `idx_flags_flagged_at` 
  ON `transaction_flags` (`flagged_at`);

CREATE INDEX `idx_flags_report_run` 
  ON `transaction_flags` (`report_run_id`);

CREATE INDEX `idx_txn_timestamp` 
  ON `transactions` (`transaction_timestamp`);

CREATE INDEX `idx_txn_account` 
  ON `transactions` (`account_number`);

CREATE INDEX `idx_txn_customer` 
  ON `transactions` (`customer_id`);

CREATE INDEX `idx_customers_name` 
  ON `customers` (`customer_name`);

CREATE INDEX `idx_runs_entity_report_time` 
  ON `compliance_report_runs` (`entity_code`, `report_type`, `started_at`);

CREATE INDEX `idx_runs_status` 
  ON `compliance_report_runs` (`run_status`);

CREATE INDEX `idx_runs_period` 
  ON `compliance_report_runs` (`period_start`, `period_end`);
