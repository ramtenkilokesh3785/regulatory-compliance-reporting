-- ============================================================================
-- Script 02: Create Tables for Regulatory Compliance Reporting
-- Database: compliance_db
-- Target Engine: MySQL 8.0.46
-- ============================================================================

USE `compliance_db`;

-- Drop existing tables in reverse dependency order
DROP TABLE IF EXISTS `transaction_flags`;
DROP TABLE IF EXISTS `transactions`;
DROP TABLE IF EXISTS `customers`;
DROP TABLE IF EXISTS `compliance_report_runs`;
DROP TABLE IF EXISTS `compliance_report_control`;

-- 1. Reporting Period Control Table
-- Tracks contiguous, non-overlapping reporting periods and sequence numbers
CREATE TABLE `compliance_report_control` (
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
CREATE TABLE `compliance_report_runs` (
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
CREATE TABLE `customers` (
  `customer_id` VARCHAR(32) PRIMARY KEY,
  `customer_name` VARCHAR(100) NOT NULL,
  `customer_type` VARCHAR(20) NOT NULL, -- e.g. INDIVIDUAL, CORPORATE
  `country` VARCHAR(3) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Transactions Table
CREATE TABLE `transactions` (
  `transaction_id` VARCHAR(64) PRIMARY KEY,
  `transaction_timestamp` TIMESTAMP NOT NULL,
  `account_number` VARCHAR(34) NOT NULL,
  `customer_id` VARCHAR(32) NOT NULL,
  `transaction_type` VARCHAR(30) NOT NULL, -- WIRE_TRANSFER, CASH_DEPOSIT, CRYPTO_PURCHASE, etc.
  `channel` VARCHAR(30) NOT NULL,          -- ONLINE, BRANCH, ATM, MOBILE
  `currency` VARCHAR(3) NOT NULL DEFAULT 'USD',
  `amount` DECIMAL(18,2) NOT NULL,
  `counterparty_name` VARCHAR(100) NULL,
  `counterparty_country` VARCHAR(3) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_txn_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Transaction Flags Table (Compliance flagged transactions)
CREATE TABLE `transaction_flags` (
  `flag_id` INT AUTO_INCREMENT PRIMARY KEY,
  `transaction_id` VARCHAR(64) NOT NULL,
  `flag_code` VARCHAR(30) NOT NULL,        -- AML_HIGH_VALUE, STRUCTURING, SANCTION_WATCH, RAPID_MOVEMENT
  `flag_reason` VARCHAR(255) NOT NULL,
  `flagged_at` TIMESTAMP NOT NULL,
  `reviewer` VARCHAR(50) NOT NULL,
  `review_status` VARCHAR(30) NOT NULL,     -- PENDING_REPORT, REPORTED, DISMISSED
  `report_run_id` VARCHAR(64) NULL,
  CONSTRAINT `fk_flag_txn` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`transaction_id`),
  CONSTRAINT `uk_txn_flag_code` UNIQUE (`transaction_id`, `flag_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
