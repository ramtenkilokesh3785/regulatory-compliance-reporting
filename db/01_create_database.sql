-- ============================================================================
-- Script 01: Create Database for Regulatory Compliance Reporting
-- Database: compliance_db
-- Target Engine: MySQL 8.0.46
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `compliance_db`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `compliance_db`;

-- Grant permissions for application user (adjust credentials as required)
-- CREATE USER IF NOT EXISTS 'compliance_app'@'%' IDENTIFIED BY 'Compliance_Secure_Pwd_2026!';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON `compliance_db`.* TO 'compliance_app'@'%';
-- FLUSH PRIVILEGES;
