# Configuration & Secure Deployment Guide

## 1. Externalized Configuration Files
The application loads properties dynamically through `config.yaml` and environment-specific overlays such as `config-dev.yaml`.

| Property | Default Value | Description |
| :--- | :--- | :--- |
| `http.port` | `8081` | HTTP API port for REST Reprocessing endpoints |
| `compliance.entityCode` | `ENT0091` | Regulated Entity Code identifier |
| `compliance.entityName` | `Apex Global Banking` | Legal entity name |
| `compliance.reportType` | `STR` | Regulatory report type code |
| `compliance.currency` | `USD` | ISO-4217 Currency Code |
| `compliance.timezone` | `UTC` | Time zone used for reporting boundaries |
| `compliance.cronExpression` | `0 0 1 * * ?` | Cron expression for automated scheduler |
| `compliance.fetchSize` | `500` | Database JDBC cursor streaming fetch size |
| `compliance.deviationThresholdPct`| `50.0` | Percentage deviation triggering volume alerts |
| `compliance.maxAttachmentSizeBytes`| `10485760` | Email gateway size limit (10 MB) |
| `directories.output` | `C:/compliance-reporting/output` | Target folder for generated active reports |
| `directories.archive` | `C:/compliance-reporting/archive`| Target folder for immutable archives |
| `database.host` | `localhost` | MySQL Server hostname |
| `database.port` | `3306` | MySQL Server port |
| `database.name` | `compliance_db` | Compliance database name |
| `database.user` | `root` | Database username |
| `database.password` | `root` | Secure database password |
| `database.maxPoolSize` | `10` | Maximum JDBC connection pool size |
| `database.minPoolSize` | `2` | Minimum JDBC connection pool size |
| `database.connectionTimeoutSeconds` | `30` | Database connection timeout in seconds |
| `email.host` | `smtp.compliance.internal.bank` | SMTP server host |
| `email.port` | `587` | SMTP server port |
| `email.from` | `compliance-dispatcher@internal.bank` | From address |
| `email.to` | `compliance-officer@internal.bank` | Notification recipient list |
| `secureLink.baseUrl`| `https://compliance.internal.bank/portal/reports/download` | Secure portal download base URL |

---

## 2. Windows Directory Setup
Create the required report directories on your local Windows system:
```powershell
New-Item -ItemType Directory -Path "C:\compliance-reporting\output" -Force
New-Item -ItemType Directory -Path "C:\compliance-reporting\archive" -Force
```

---

## 3. Database Configuration & Setup
Run the automated repeatable setup script or individual SQL scripts:
```powershell
# Safe, repeatable initialization (idempotent, does NOT drop tables or overwrite data):
powershell -ExecutionPolicy Bypass -File db/setup_database.ps1 -User root -Password root

# Or run the repeatable SQL script directly:
mysql -u root -p < db/init_compliance_db_repeatable.sql

# Optional: To perform a complete clean reset with reseeded data:
powershell -ExecutionPolicy Bypass -File db/setup_database.ps1 -User root -Password root -Reset
```

---

## 4. Secure Properties & Environment Injection
For production environments, pass sensitive credentials via JVM system properties or environment variables during startup:
```bash
-Ddatabase.password=YourActualDbPassword \
-Ddb.password=YourActualDbPassword \
-Demail.password=YourActualSmtpPassword \
-Dmule.env=prod
```
The application's `mule-artifact.json` registers `database.password`, `db.password`, `email.password`, and `secureLink.secretKey` as masked secure properties to guarantee they are never exposed in log files or console output.
