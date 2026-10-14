-- ============================================================================
-- Script: init_compliance_db_repeatable.sql
-- Repeatable, Idempotent Database Initialization for Regulatory Compliance Reporting
-- Database: compliance_db
-- Target Engine: MySQL Community Server 8.0.46
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `compliance_db`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `compliance_db`;

-- 1. Reporting Period Control Table
-- Tracks contiguous, non-overlapping reporting periods and sequence numbers
CREATE TABLE IF NOT EXISTS `compliance_report_control` (
  `control_id` INT AUTO_INCREMENT PRIMARY KEY,
  `entity_code` VARCHAR(20) NOT NULL,
  `report_type` VARCHAR(20) NOT NULL,
  `last_success_period_end` TIMESTAMP NOT NULL,
  `current_sequence_number` INT NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `uk_control_entity_report` UNIQUE (`entity_code`, `report_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Compliance Report Runs (Audit & State Machine Table)
-- Tracks each execution lifecycle: RUNNING -> REPORT_GENERATED -> ARCHIVED -> NOTIFIED -> SUCCESS / FAILED
CREATE TABLE IF NOT EXISTS `compliance_report_runs` (
  `run_id` VARCHAR(64) PRIMARY KEY,
  `entity_code` VARCHAR(20) NOT NULL,
  `entity_name` VARCHAR(100) NOT NULL,
  `report_type` VARCHAR(20) NOT NULL,
  `period_start` TIMESTAMP NOT NULL,
  `period_end` TIMESTAMP NOT NULL,
  `sequence_number` INT NOT NULL,
  `is_revision` BOOLEAN NOT NULL DEFAULT FALSE,
  `record_count` INT NOT NULL DEFAULT 0,
  `total_amount` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  `customer_count` INT NOT NULL DEFAULT 0,
  `completeness_result` VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  `is_nil_report` BOOLEAN NOT NULL DEFAULT FALSE,
  `output_file_path` VARCHAR(255) NULL,
  `archive_file_path` VARCHAR(255) NULL,
  `summary_file_path` VARCHAR(255) NULL,
  `checksum` VARCHAR(64) NULL,
  `notification_status` VARCHAR(30) NOT NULL DEFAULT 'PENDING',
  `notification_mode` VARCHAR(30) NULL,
  `trigger_source` VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
  `run_status` VARCHAR(30) NOT NULL DEFAULT 'RUNNING',
  `error_message` TEXT NULL,
  `correlation_id` VARCHAR(64) NULL,
  `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` TIMESTAMP NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Customers Table
CREATE TABLE IF NOT EXISTS `customers` (
  `customer_id` VARCHAR(32) PRIMARY KEY,
  `customer_name` VARCHAR(100) NOT NULL,
  `customer_type` VARCHAR(20) NOT NULL,
  `country` VARCHAR(3) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Transactions Table
CREATE TABLE IF NOT EXISTS `transactions` (
  `transaction_id` VARCHAR(64) PRIMARY KEY,
  `transaction_timestamp` TIMESTAMP NOT NULL,
  `account_number` VARCHAR(34) NOT NULL,
  `customer_id` VARCHAR(32) NOT NULL,
  `transaction_type` VARCHAR(30) NOT NULL,
  `channel` VARCHAR(30) NOT NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'USD',
  `amount` DECIMAL(18,2) NOT NULL,
  `counterparty_name` VARCHAR(100) NULL,
  `counterparty_country` VARCHAR(3) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_txn_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Transaction Flags Table (Compliance flagged transactions)
CREATE TABLE IF NOT EXISTS `transaction_flags` (
  `flag_id` INT AUTO_INCREMENT PRIMARY KEY,
  `transaction_id` VARCHAR(64) NOT NULL,
  `flag_code` VARCHAR(30) NOT NULL,
  `flag_reason` VARCHAR(255) NOT NULL,
  `flagged_at` TIMESTAMP NOT NULL,
  `reviewer` VARCHAR(50) NOT NULL,
  `review_status` VARCHAR(30) NOT NULL,
  `report_run_id` VARCHAR(64) NULL,
  CONSTRAINT `fk_flag_txn` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`transaction_id`),
  CONSTRAINT `uk_txn_flag_code` UNIQUE (`transaction_id`, `flag_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Indexes for Optimized Extraction and Audit Performance
-- Create indexes using helper procedure if not existing
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS create_index_if_missing(
    IN p_table VARCHAR(64),
    IN p_index VARCHAR(64),
    IN p_columns VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.statistics 
        WHERE table_schema = DATABASE() 
          AND table_name = p_table 
          AND index_name = p_index
    ) THEN
        SET @sql = CONCAT('CREATE INDEX `', p_index, '` ON `', p_table, '` (', p_columns, ')');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END //
DELIMITER ;

CALL create_index_if_missing('transaction_flags', 'idx_flags_status_flagged_txn', '`review_status`, `flagged_at`, `transaction_id`');
CALL create_index_if_missing('transaction_flags', 'idx_flags_flagged_at', '`flagged_at`');
CALL create_index_if_missing('transaction_flags', 'idx_flags_report_run', '`report_run_id`');
CALL create_index_if_missing('transactions', 'idx_txn_timestamp', '`transaction_timestamp`');
CALL create_index_if_missing('transactions', 'idx_txn_account', '`account_number`');
CALL create_index_if_missing('transactions', 'idx_txn_customer', '`customer_id`');
CALL create_index_if_missing('customers', 'idx_customers_name', '`customer_name`');
CALL create_index_if_missing('compliance_report_runs', 'idx_runs_entity_report_time', '`entity_code`, `report_type`, `started_at`');
CALL create_index_if_missing('compliance_report_runs', 'idx_runs_status', '`run_status`');
CALL create_index_if_missing('compliance_report_runs', 'idx_runs_period', '`period_start`, `period_end`');

DROP PROCEDURE IF EXISTS create_index_if_missing;

-- 7. Baseline Seed Data (Insert Ignore to ensure repeatability without overwriting)
INSERT IGNORE INTO `compliance_report_control` 
  (`control_id`, `entity_code`, `report_type`, `last_success_period_end`, `current_sequence_number`)
VALUES 
  (1, 'ENT0091', 'STR', '2026-09-10 23:59:59', 0);

INSERT IGNORE INTO `customers` (`customer_id`, `customer_name`, `customer_type`, `country`) VALUES
  ('CUST001', 'lokesh', 'INDIVIDUAL', 'USA'),
  ('CUST002', 'sai', 'INDIVIDUAL', 'GBR'),
  ('CUST003', 'naidhruv', 'CORPORATE', 'SGP'),
  ('CUST004', 'irish', 'INDIVIDUAL', 'CAN'),
  ('CUST005', 'janani', 'CORPORATE', 'IND'),
  ('CUST006', 'pranav', 'INDIVIDUAL', 'DEU');

INSERT IGNORE INTO `transactions` 
  (`transaction_id`, `transaction_timestamp`, `account_number`, `customer_id`, `transaction_type`, `channel`, `currency`, `amount`, `counterparty_name`, `counterparty_country`) 
VALUES
  ('TXN10001', '2026-09-11 08:15:30', 'ACC987654321', 'CUST001', 'WIRE_TRANSFER', 'ONLINE', 'USD', 250000.00, 'Alpine Holdings AG', 'CHE'),
  ('TXN10002', '2026-09-11 09:30:15', 'ACC123456789', 'CUST002', 'CASH_DEPOSIT', 'BRANCH', 'USD', 9900.00, 'Self Deposit Structuring', 'GBR'),
  ('TXN10003', '2026-09-11 11:45:00', 'ACC555666777', 'CUST003', 'WIRE_TRANSFER', 'ONLINE', 'USD', 750000.00, 'Pacific Maritime Ltd', 'PAN'),
  ('TXN10004', '2026-09-11 14:20:10', 'ACC222333444', 'CUST004', 'CRYPTO_PURCHASE', 'MOBILE', 'USD', 45000.00, 'Global Coin Exchange', 'CYP'),
  ('TXN10005', '2026-09-11 16:50:45', 'ACC999888111', 'CUST005', 'WIRE_TRANSFER', 'ONLINE', 'USD', 320000.00, 'Eastern Tech Ventures', 'ARE'),
  ('TXN10006', '2026-09-11 19:10:00', 'ACC444555888', 'CUST006', 'INTERNATIONAL_PAYMENT', 'ONLINE', 'USD', 85000.00, 'Bavaria Asset Management', 'DEU'),
  ('TXN09001', '2026-09-10 10:00:00', 'ACC987654321', 'CUST001', 'WIRE_TRANSFER', 'USD', 'USD', 120000.00, 'Nordic Prime Corp', 'SWE'),
  ('TXN09002', '2026-09-10 15:30:00', 'ACC123456789', 'CUST002', 'WIRE_TRANSFER', 'USD', 'USD', 210000.00, 'London Capital Partners', 'GBR'),
  ('TXN12001', '2026-09-12 09:00:00', 'ACC555666777', 'CUST003', 'WIRE_TRANSFER', 'ONLINE', 'USD', 400000.00, 'Singapore Trading Hub', 'SGP');

INSERT IGNORE INTO `transaction_flags` 
  (`flag_id`, `transaction_id`, `flag_code`, `flag_reason`, `flagged_at`, `reviewer`, `review_status`, `report_run_id`) 
VALUES
  (1, 'TXN10001', 'AML_HIGH_VALUE', 'Cross-border wire transfer exceeds 200k USD threshold', '2026-09-11 08:30:00', 'lokesh', 'PENDING_REPORT', NULL),
  (2, 'TXN10002', 'STRUCTURING', 'Sequential cash deposits just below mandatory declaration limit', '2026-09-11 09:45:00', 'sai', 'PENDING_REPORT', NULL),
  (3, 'TXN10003', 'SANCTION_WATCH', 'High risk jurisdiction offshore wire counterparty', '2026-09-11 12:00:00', 'naidhruv', 'PENDING_REPORT', NULL),
  (4, 'TXN10004', 'RAPID_MOVEMENT', 'Immediate conversion to high-risk virtual asset service provider', '2026-09-11 14:35:00', 'irish', 'PENDING_REPORT', NULL),
  (5, 'TXN10005', 'AML_HIGH_VALUE', 'Significant international corporate transfer to Free Trade Zone', '2026-09-11 17:15:00', 'janani', 'PENDING_REPORT', NULL),
  (6, 'TXN10006', 'RAPID_MOVEMENT', 'Rapid multi-hop routing with low latency settlement', '2026-09-11 19:30:00', 'pranav', 'PENDING_REPORT', NULL);
