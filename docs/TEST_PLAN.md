# Comprehensive Test Plan & MUnit Traceability

## 1. Test Strategy & Scope
The test suite utilizes MUnit 3.7.3 compatible with Mule Runtime 4.12.2 and Java 17. All database calls, file system operations, and SMTP network transports are fully mocked to enable deterministic, isolated unit testing without requiring active external servers.

---

## 2. Traceability Matrix: 17 Mandatory Negative Scenarios

| Scenario # | Negative Scenario Description | Implementation Component | MUnit Test Case | Expected Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **1** | No qualifying transactions | `compliance-main.xml` | `test-compliance-orchestrator-nil-report` | Header generated, Trailer with `0\|0.00\|0\|NIL_REPORT`, summary written, email sent, control advanced. |
| **2** | Completeness mismatch | `report-subflows.xml` | `test-compliance-orchestrator-completeness-mismatch` | Raises `COMPLIANCE:COMPLETENESS_MISMATCH`, stops flow before file/email, marks FAILED, control preserved. |
| **3** | Gap or overlap between periods | `database-subflows.xml` | `test-get-reporting-period-control-subflow` | Period start strictly derived from `last_success_period_end + 1s` and end is `start + 1 day 23:59:59`. |
| **4** | Failed run must not advance control | `error-handling.xml` | `test-compliance-orchestrator-completeness-mismatch` | Reporting control table update skipped; `last_success_period_end` unchanged. |
| **5** | Duplicate run for same period | `compliance-api.xml` | `test-get-reporting-period-control-subflow` | Sequence incremented, `is_revision = true`, new revision created without overwriting original. |
| **6** | Archive overwrite attempt | `file-subflows.xml` | `test-generate-report-payloads` | File Connector `mode="CREATE_NEW"` rejects overwrite; raises `COMPLIANCE:ARCHIVE_COLLISION`. |
| **7** | High-volume period | `database-subflows.xml` | `test-extract-flagged-transactions-subflow` | Uses streaming cursor with `fetchSize=500` to prevent memory exhaustion. |
| **8** | Oversized attachment | `file-subflows.xml` / `notification-subflows.xml` | `test-send-compliance-notification-secure-link` | Byte size evaluated against `10MB`; switches to `SECURE_LINK` mode with portal token. |
| **9** | Missing customer reference data | `database-subflows.xml` | `05_test_scenarios.sql` | Inner join / sanitized DataWeave replaces null customer references safely. |
| **10** | Invalid or unparseable data | `report-subflows.xml` | `test-generate-report-payloads` | Sanitizer cleans illegal pipes `\|` and control characters; numbers formatted strictly. |
| **11** | Time-zone and boundary errors | `database-subflows.xml` | `test-get-reporting-period-control-subflow` | Exact boundary condition `flagged_at >= periodStart AND flagged_at < periodEnd` applied. |
| **12** | Database connectivity or timeout | `database-config.xml` / `error-handling.xml` | `global-compliance-error-handler` | Reconnect strategy retries 3 times; records FAILED status in audit log. |
| **13** | File system or permission failure | `error-handling.xml` | `global-compliance-error-handler` | Catches `FILE:ACCESS_DENIED`, sets run status FAILED, alerts compliance admin. |
| **14** | Email delivery failure | `notification-subflows.xml` | `test-smtp-failure-handling` | Bounded retries (3x); marks `notification_status = 'FAILED'`, leaves audit trail. |
| **15** | Missed schedule or restart | `database-subflows.xml` | `get-reporting-period-control-subflow` | Next run queries `last_success_period_end` to seamlessly pick up missed historical periods. |
| **16** | Unexpected processing error | `error-handling.xml` | `global-compliance-error-handler` | `ANY` handler catches runtime exception, records correlation ID, leaves control unchanged. |
| **17** | Collision on revision archive | `file-subflows.xml` | `write-and-archive-reports-subflow` | Incorporates sequence number into file name (`_001.csv`, `_002.csv`) to ensure unique keys. |

---

## 3. Running MUnit Tests via Maven
Run the test suite directly from command line:
```powershell
mvn clean test
```
Or execute specific test files:
```powershell
mvn test -Dtest=compliance-main-test.xml
```
