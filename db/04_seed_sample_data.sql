-- ============================================================================
-- Script 04: Seed Sample Data for Regulatory Compliance Reporting
-- Database: compliance_db
-- Target Engine: MySQL 8.0.46
-- ============================================================================

USE `compliance_db`;

-- Clear existing data
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `transaction_flags`;
TRUNCATE TABLE `transactions`;
TRUNCATE TABLE `customers`;
TRUNCATE TABLE `compliance_report_runs`;
TRUNCATE TABLE `compliance_report_control`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Initial Compliance Reporting Control Record
-- Configured for Entity ENT0091, Report Type STR
-- Last successful period ended at 2026-09-10 23:59:59 UTC
INSERT INTO `compliance_report_control` 
  (`control_id`, `entity_code`, `report_type`, `last_success_period_end`, `current_sequence_number`)
VALUES 
  (1, 'ENT0091', 'STR', '2026-09-10 23:59:59', 0);

-- 2. Seed Customers (incorporating required names: lokesh, sai, naidhruv, irish, janani, pranav)
INSERT INTO `customers` (`customer_id`, `customer_name`, `customer_type`, `country`) VALUES
  ('CUST001', 'Lokesh Sharma', 'INDIVIDUAL', 'USA'),
  ('CUST002', 'Sai Kumar', 'INDIVIDUAL', 'GBR'),
  ('CUST003', 'Naidhruv Patel', 'CORPORATE', 'SGP'),
  ('CUST004', 'Irish Gupta', 'INDIVIDUAL', 'CAN'),
  ('CUST005', 'Janani Ramakrishnan', 'CORPORATE', 'IND'),
  ('CUST006', 'Pranav Verma', 'INDIVIDUAL', 'DEU');

-- 3. Seed Transactions
INSERT INTO `transactions` 
  (`transaction_id`, `transaction_timestamp`, `account_number`, `customer_id`, `transaction_type`, `channel`, `currency`, `amount`, `counterparty_name`, `counterparty_country`) 
VALUES
  -- Transactions for Period 2026-09-11 (Eligible for standard run)
  ('TXN10001', '2026-09-11 08:15:30', 'ACC987654321', 'CUST001', 'WIRE_TRANSFER', 'ONLINE', 'USD', 250000.00, 'Alpine Holdings AG', 'CHE'),
  ('TXN10002', '2026-09-11 09:30:15', 'ACC123456789', 'CUST002', 'CASH_DEPOSIT', 'BRANCH', 'USD', 9900.00, 'Self Deposit Structuring', 'GBR'),
  ('TXN10003', '2026-09-11 11:45:00', 'ACC555666777', 'CUST003', 'WIRE_TRANSFER', 'ONLINE', 'USD', 750000.00, 'Pacific Maritime Ltd', 'PAN'),
  ('TXN10004', '2026-09-11 14:20:10', 'ACC222333444', 'CUST004', 'CRYPTO_PURCHASE', 'MOBILE', 'USD', 45000.00, 'Global Coin Exchange', 'CYP'),
  ('TXN10005', '2026-09-11 16:50:45', 'ACC999888111', 'CUST005', 'WIRE_TRANSFER', 'ONLINE', 'USD', 320000.00, 'Eastern Tech Ventures', 'ARE'),
  ('TXN10006', '2026-09-11 19:10:00', 'ACC444555888', 'CUST006', 'INTERNATIONAL_PAYMENT', 'ONLINE', 'USD', 85000.00, 'Bavaria Asset Management', 'DEU'),

  -- Historical Transactions (Already reported in previous periods)
  ('TXN09001', '2026-09-10 10:00:00', 'ACC987654321', 'CUST001', 'WIRE_TRANSFER', 'ONLINE', 'USD', 120000.00, 'Nordic Prime Corp', 'SWE'),
  ('TXN09002', '2026-09-10 15:30:00', 'ACC123456789', 'CUST002', 'WIRE_TRANSFER', 'ONLINE', 'USD', 210000.00, 'London Capital Partners', 'GBR'),

  -- Future Transactions (Period 2026-09-12)
  ('TXN12001', '2026-09-12 09:00:00', 'ACC555666777', 'CUST003', 'WIRE_TRANSFER', 'ONLINE', 'USD', 400000.00, 'Singapore Trading Hub', 'SGP');

-- 4. Seed Transaction Flags (with reviewers: lokesh, sai, naidhruv, irish, janani, pranav)
INSERT INTO `transaction_flags` 
  (`flag_id`, `transaction_id`, `flag_code`, `flag_reason`, `flagged_at`, `reviewer`, `review_status`, `report_run_id`) 
VALUES
  -- Flags for Period 2026-09-11 (Eligible for extraction: PENDING_REPORT)
  (1, 'TXN10001', 'AML_HIGH_VALUE', 'Cross-border wire transfer exceeds 200k USD threshold', '2026-09-11 08:30:00', 'lokesh', 'PENDING_REPORT', NULL),
  (2, 'TXN10002', 'STRUCTURING', 'Sequential cash deposits just below mandatory declaration limit', '2026-09-11 09:45:00', 'sai', 'PENDING_REPORT', NULL),
  (3, 'TXN10003', 'SANCTION_WATCH', 'High risk jurisdiction offshore wire counterparty', '2026-09-11 12:00:00', 'naidhruv', 'PENDING_REPORT', NULL),
  (4, 'TXN10004', 'RAPID_MOVEMENT', 'Immediate conversion to high-risk virtual asset service provider', '2026-09-11 14:35:00', 'irish', 'PENDING_REPORT', NULL),
  (5, 'TXN10005', 'AML_HIGH_VALUE', 'Significant international corporate transfer to Free Trade Zone', '2026-09-11 17:15:00', 'janani', 'PENDING_REPORT', NULL),
  (6, 'TXN10006', 'RAPID_MOVEMENT', 'Rapid multi-hop routing with low latency settlement', '2026-09-11 19:30:00', 'pranav', 'PENDING_REPORT', NULL),

  -- Historical Flags (Already reported)
  (7, 'TXN09001', 'AML_HIGH_VALUE', 'High value offshore transfer', '2026-09-10 10:15:00', 'lokesh', 'REPORTED', 'RUN-HIST-20260910-001'),
  (8, 'TXN09002', 'STRUCTURING', 'Structuring pattern identified', '2026-09-10 15:45:00', 'sai', 'REPORTED', 'RUN-HIST-20260910-001'),

  -- Future Flags (Period 2026-09-12)
  (9, 'TXN12001', 'AML_HIGH_VALUE', 'High value trade transaction', '2026-09-12 09:30:00', 'naidhruv', 'PENDING_REPORT', NULL);

-- 5. Seed Historical Runs for Trailing Average Calculation (Volume Deviation Baseline)
INSERT INTO `compliance_report_runs` 
  (`run_id`, `entity_code`, `entity_name`, `report_type`, `period_start`, `period_end`, `sequence_number`, `is_revision`, `record_count`, `total_amount`, `customer_count`, `completeness_result`, `is_nil_report`, `run_status`, `started_at`, `completed_at`) 
VALUES
  ('RUN-HIST-20260908-001', 'ENT0091', 'Apex Global Banking', 'STR', '2026-09-08 00:00:00', '2026-09-08 23:59:59', 1, FALSE, 5, 1200000.00, 4, 'PASS', FALSE, 'SUCCESS', '2026-09-08 23:59:59', '2026-09-09 00:02:10'),
  ('RUN-HIST-20260909-001', 'ENT0091', 'Apex Global Banking', 'STR', '2026-09-09 00:00:00', '2026-09-09 23:59:59', 1, FALSE, 6, 1400000.00, 5, 'PASS', FALSE, 'SUCCESS', '2026-09-09 23:59:59', '2026-09-10 00:02:15'),
  ('RUN-HIST-20260910-001', 'ENT0091', 'Apex Global Banking', 'STR', '2026-09-10 00:00:00', '2026-09-10 23:59:59', 1, FALSE, 2, 330000.00, 2, 'PASS', FALSE, 'SUCCESS', '2026-09-10 23:59:59', '2026-09-11 00:01:45');
