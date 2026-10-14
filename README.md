# Regulatory Compliance Reporting Application

[![MuleSoft Runtime](https://img.shields.io/badge/Mule_Runtime-4.12.2-blue.svg)](https://www.mulesoft.com/)
[![Java](https://img.shields.io/badge/Java-17_LTS-orange.svg)](https://openjdk.org/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0.46-00758F.svg)](https://www.mysql.com/)
[![MUnit](https://img.shields.io/badge/MUnit-3.7.3-brightgreen.svg)](https://docs.mulesoft.com/munit/latest/)

An enterprise MuleSoft 4.12.2 integration application implementing automated **Regulatory Compliance Reporting (AML / STR)** in strict compliance with **Use Case 12: Compliance — Regulatory Compliance Reporting**.

---

## 1. Project Overview & Features
- **Automated Scheduled Reporting**: Configurable Cron Scheduler executing compliant period calculations.
- **Reporting Period Control**: Contiguous, non-overlapping reporting periods governed by `compliance_report_control`.
- **Streamed Extraction**: Database cursor streaming (`fetchSize=500`) with deterministic sorting.
- **Independent Completeness Reconciliation**: Dual query comparison (record count, total monetary amount, distinct customer count) preventing unauthorized submissions.
- **Prescribed Pipe-Delimited Layout**: Compliant Header (`H`), Detail (`D`), and Trailer (`T`) formatting.
- **Cryptographic SHA-256 Checksum**: Canonical hash calculated on detail records for tamper-evident validation.
- **Dual Output Deliverables**: Machine-readable regulatory submission CSV and human-readable executive summary text file.
- **Collision-Safe Immutable Archival**: Dedicated write policies preventing overwrites of historical compliance filings.
- **Volume Deviation Analysis**: Trailing 30-day baseline comparison flagging unusual volume anomalies.
- **Smart Notification Dispatch**: Multi-mode SMTP delivery (direct attachments or secure portal fallback).
- **REST Reprocessing API**: RAML 1.0 / APIkit endpoints for manual runs, historical reruns, and audit trail retrieval.
- **Global Error Handling & State Machine**: State transitions (`RUNNING` $\rightarrow$ `REPORT_GENERATED` $\rightarrow$ `ARCHIVED` $\rightarrow$ `NOTIFIED` $\rightarrow$ `SUCCESS` / `FAILED`) ensuring control pointers are preserved on failure.

---

## 2. Project Directory Layout

```
regulatory-compliance-reporting/
├── pom.xml                                   # Maven configuration with Mule 4.12.2 & MUnit 3.7.3
├── mule-artifact.json                        # Secure properties & Mule artifact metadata
├── README.md                                 # Master documentation & execution instructions
├── .gitignore / .gitattributes               # Version control rules
├── docs/                                     # Technical Documentation
│   ├── HIGH_LEVEL_DESIGN.md                  # System overview, sequences, and component roles
│   ├── ARCHITECTURE.md                       # Technical architecture & layout specifications
│   ├── CONFIGURATION_GUIDE.md                # Environment settings, properties, & setup
│   ├── TEST_PLAN.md                          # Negative scenarios & MUnit traceability matrix
│   ├── ACCEPTANCE_CRITERIA.md                # PDF criteria verification checklist
│   └── TROUBLESHOOTING.md                    # Common errors and resolutions
├── db/                                       # MySQL 8.0.46 Scripts
│   ├── 01_create_database.sql                # Database creation script (compliance_db)
│   ├── 02_create_tables.sql                  # Control, runs, customers, txns, flags tables
│   ├── 03_create_indexes.sql                 # High-performance query indexes
│   ├── 04_seed_sample_data.sql               # Seed data with required names
│   └── 05_test_scenarios.sql                 # Verification queries and scenario fixtures
└── src/
    ├── main/
    │   ├── mule/                             # Mule Flows & Configurations
    │   │   ├── compliance-main.xml           # Scheduled trigger & orchestrator state machine
    │   │   ├── compliance-api.xml            # APIkit router & REST API endpoints
    │   │   ├── database-config.xml           # Connector configs (DB, File, Email, HTTP)
    │   │   ├── database-subflows.xml         # Extraction, control, aggregate, & audit subflows
    │   │   ├── report-subflows.xml           # Completeness, DW transformations, & SHA-256
    │   │   ├── file-subflows.xml             # Output writing, immutable archival, & size checks
    │   │   ├── notification-subflows.xml     # HTML email rendering & SMTP delivery
    │   │   └── error-handling.xml            # Global error handler & state rollback
    │   └── resources/
    │       ├── api/compliance-api.raml       # RAML 1.0 API specification
    │       ├── dw/                           # DataWeave 2.0 Transformation Files
    │       │   ├── submission-header.dwl     # Prescribed Header (H) record
    │       │   ├── submission-detail.dwl     # Prescribed Detail (D) records
    │       │   ├── submission-trailer.dwl    # Prescribed Trailer (T) record
    │       │   ├── report-summary.dwl        # Human-readable summary report
    │       │   ├── email-body.dwl            # HTML notification template
    │       │   └── volume-analysis.dwl       # Trailing average deviation calculations
    │       ├── config.yaml                   # Base configuration
    │       ├── config-dev.yaml               # Development configuration
    │       └── log4j2.xml                    # Logging configuration
    └── test/
        └── munit/                            # MUnit 3.7.3 Test Suite
            ├── compliance-main-test.xml      # End-to-end orchestration tests
            ├── database-subflows-test.xml    # Database & control subflow tests
            ├── report-subflows-test.xml      # Completeness & report generation tests
            └── notification-subflows-test.xml# Email & secure link tests
```

---

## 3. Database Setup (MySQL 8.0.46)
Execute the SQL scripts in order using MySQL CLI or Workbench:
```powershell
mysql -u root -p < db/01_create_database.sql
mysql -u root -p compliance_db < db/02_create_tables.sql
mysql -u root -p compliance_db < db/03_create_indexes.sql
mysql -u root -p compliance_db < db/04_seed_sample_data.sql
```

---

## 4. Local File Directory Setup
Ensure the output and archive folders exist on Windows:
```powershell
New-Item -ItemType Directory -Path "C:\compliance-reporting\output" -Force
New-Item -ItemType Directory -Path "C:\compliance-reporting\archive" -Force
```

---

## 5. Anypoint Studio Import & Run Instructions
1. Open **Anypoint Studio 7.28+**.
2. Select **File $\rightarrow$ Import... $\rightarrow$ Anypoint Studio $\rightarrow$ Packaged mule application (.jar / .zip) or Existing Mule Project into Workspace**.
3. Point to `c:\MuleWorkspace\mulesoft-hackathon-project\regulatory-compliance-reporting`.
4. Ensure **Mule Server 4.12.2 EE** and **Java 17** are selected in Project Properties.
5. Right-click the project root $\rightarrow$ **Run As $\rightarrow$ Mule Application**.

---

## 6. Testing & Validation via REST API

### Trigger Manual / Historical Run:
```http
POST http://localhost:8081/api/v1/reports/run
Content-Type: application/json

{
  "entityCode": "ENT0091",
  "reportType": "STR",
  "periodStart": "2026-09-11 00:00:00",
  "periodEnd": "2026-09-11 23:59:59",
  "isHistoricalReprocess": false
}
```

### Check Run Audit Record:
```http
GET http://localhost:8081/api/v1/reports/runs/RUN-20260911-001
```

### List Run History:
```http
GET http://localhost:8081/api/v1/reports/runs?limit=10&offset=0
```

---

## 7. Running MUnit Tests via Maven
Run the complete automated test suite from the terminal:
```powershell
mvn clean test
```
All external dependencies (database, disk, and SMTP) are mocked in the MUnit suite.
