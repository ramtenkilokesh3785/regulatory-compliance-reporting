# Troubleshooting & Diagnostics Guide

## 1. Common Issues & Solutions

### A. Database Connection Failures (`DB:CONNECTIVITY`)
- **Symptom**: `Communications link failure` or `Access denied for user 'root'@'localhost'`.
- **Diagnosis**: Verify MySQL 8.0 server service is running (`Get-Service MySQL80` or `mysqladmin ping`).
- **Fix**: Check `database.user` and `database.password` in `src/main/resources/config-dev.yaml`. Ensure MySQL accepts local connections on port 3306.

### B. Output / Archive File Access Denied (`FILE:ACCESS_DENIED`)
- **Symptom**: `Failed to create file: C:/compliance-reporting/output/...`
- **Diagnosis**: Target Windows directory does not exist or user lacks write permissions.
- **Fix**: Execute PowerShell as administrator:
  ```powershell
  New-Item -ItemType Directory -Path "C:\compliance-reporting\output", "C:\compliance-reporting\archive" -Force
  ```

### C. Archive File Already Exists (`FILE:FILE_ALREADY_EXISTS` / `COMPLIANCE:ARCHIVE_COLLISION`)
- **Symptom**: `Target file already exists in archive`.
- **Diagnosis**: An attempt was made to write to an archived sequence number without marking the run as a revision.
- **Fix**: Trigger historical rerun with `isHistoricalReprocess=true` or allocate the next sequence number.

### D. Completeness Check Mismatch (`COMPLIANCE:COMPLETENESS_MISMATCH`)
- **Symptom**: `CRITICAL: Completeness mismatch detected! Extracted vs Aggregate count/amount mismatch`.
- **Diagnosis**: Concurrent database transaction committed during extraction or uncommitted dirty reads.
- **Fix**: Ensure isolation level in MySQL supports repeatable read and review uncommitted flags in `transaction_flags`.

### E. SMTP Connection Timeout (`EMAIL:CONNECTIVITY`)
- **Symptom**: `Could not connect to SMTP host: smtp.compliance.internal.bank`.
- **Diagnosis**: SMTP firewall or invalid port.
- **Fix**: For local development, configure a mock SMTP server (e.g. MailHog on port 1025) or update `email.host` in `config-dev.yaml`.

---

## 2. Inspecting Log Files
Mule runtime logs are written to:
`logs/regulatory-compliance-reporting.log`
Filter by correlation ID or Run ID to trace a specific reporting cycle:
```powershell
Select-String -Path "logs\regulatory-compliance-reporting.log" -Pattern "RUN-2026"
```
