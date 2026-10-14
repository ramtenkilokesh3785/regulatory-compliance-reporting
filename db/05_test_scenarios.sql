-- ============================================================================
-- Script 05: Test Scenarios & Verification SQL
-- Database: compliance_db
-- Target Engine: MySQL 8.0.46
-- ============================================================================

USE `compliance_db`;

-- ----------------------------------------------------------------------------
-- Test Scenario 1: Verify Standard Extraction for Period 2026-09-11
-- ----------------------------------------------------------------------------
SELECT 
  t.transaction_id,
  t.transaction_timestamp,
  t.account_number,
  c.customer_id,
  c.customer_name,
  c.customer_type,
  t.transaction_type,
  t.channel,
  t.currency,
  t.amount,
  t.counterparty_name,
  t.counterparty_country,
  f.flag_code,
  f.flag_reason,
  f.flagged_at,
  f.reviewer,
  f.review_status
FROM transaction_flags f
JOIN transactions t ON f.transaction_id = t.transaction_id
JOIN customers c ON t.customer_id = c.customer_id
WHERE f.review_status = 'PENDING_REPORT'
  AND f.flagged_at >= '2026-09-11 00:00:00'
  AND f.flagged_at < '2026-09-11 23:59:59'
ORDER BY f.flagged_at ASC, t.transaction_id ASC;

-- ----------------------------------------------------------------------------
-- Test Scenario 2: Verify Independent Completeness Aggregate for Period 2026-09-11
-- ----------------------------------------------------------------------------
SELECT 
  COUNT(f.flag_id) AS total_records,
  COALESCE(SUM(t.amount), 0.00) AS total_amount,
  COUNT(DISTINCT c.customer_id) AS total_customers
FROM transaction_flags f
JOIN transactions t ON f.transaction_id = t.transaction_id
JOIN customers c ON t.customer_id = c.customer_id
WHERE f.review_status = 'PENDING_REPORT'
  AND f.flagged_at >= '2026-09-11 00:00:00'
  AND f.flagged_at < '2026-09-11 23:59:59';

-- ----------------------------------------------------------------------------
-- Test Scenario 3: Check Latest Reporting Control & Audit Runs
-- ----------------------------------------------------------------------------
SELECT * FROM `compliance_report_control` WHERE `entity_code` = 'ENT0091' AND `report_type` = 'STR';
SELECT * FROM `compliance_report_runs` ORDER BY `started_at` DESC LIMIT 10;

-- ----------------------------------------------------------------------------
-- Test Scenario 4: Setup a Nil-Report Scenario (Advance control to 2026-09-13 where no transactions exist)
-- ----------------------------------------------------------------------------
-- UPDATE compliance_report_control 
-- SET last_success_period_end = '2026-09-12 23:59:59' 
-- WHERE entity_code = 'ENT0091' AND report_type = 'STR';

-- ----------------------------------------------------------------------------
-- Test Scenario 5: Reset Database to Initial Seed State for Fresh Execution
-- ----------------------------------------------------------------------------
-- SOURCE db/04_seed_sample_data.sql;
