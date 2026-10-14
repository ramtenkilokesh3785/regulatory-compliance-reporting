# Architecture & Technical Design Specification

## 1. System Architecture

The architecture adheres to MuleSoft recommended API-Led and Event-Driven Integration patterns, encapsulating extraction, validation, transformation, persistence, and dispatch into decoupled, reusable subflows.

```
+-----------------------------------------------------------------------------------+
|                           MULE RUNTIME 4.12.2 (JAVA 17)                           |
|                                                                                   |
|  [Scheduler Trigger]   [HTTP Listener: 8081 / APIkit Router: compliance-api.raml] |
|           |                                       |                               |
|           +-------------------+-------------------+                               |
|                               |                                                   |
|                [compliance-orchestrator-flow]                                     |
|                               |                                                   |
|    +--------------------------+--------------------------+                        |
|    |                          |                          |                        |
| [database-subflows]   [report-subflows]          [file-subflows]                  |
|    | (JDBC MySQL)             | (DataWeave 2.0)          | (Windows FS)           |
|    |                          |                          |                        |
|    | - Control Lookup         | - Completeness Engine    | - Output Writer        |
|    | - Streamed Select        | - Pipe Layout (H/D/T)    | - Immutable Archival   |
|    | - Aggregate Validation   | - SHA-256 Checksum       | - Size Evaluation      |
|    | - Audit State Updates    | - Summary Generator      |                        |
|    | - Control Advancement    | - Volume Analysis        |                        |
|    +--------------------------+--------------------------+                        |
|                               |                                                   |
|                     [notification-subflows]                                       |
|                     (Email SMTP / TLS 1.3)                                        |
|                     - HTML Template Rendering                                     |
|                     - Attachment / Secure Link Fallback                           |
|                                                                                   |
|  [global-compliance-error-handler] (State machine rollback & Audit persistence)   |
+-----------------------------------------------------------------------------------+
```

---

## 2. Prescribed Pipe-Delimited File Specification

### Header Record (H)
Format: `H|entityCode|entityName|reportType|periodDate|generatedAt|sequenceNumber|currency`
- Example: `H|ENT0091|Apex Global Banking|STR|2026-09-11|2026-09-11T23:59:59Z|001|USD`

### Detail Record (D)
Format: `D|serial|transactionId|transactionDateTime|accountNumber|customerId|customerName|customerType|transactionType|channel|currency|amount|counterpartyName|counterpartyCountry|flagCode|flagReason|flaggedAt|reviewedBy|reviewStatus`
- Sorting: Strictly deterministic ordering by `flagged_at ASC, transaction_id ASC`.
- Example: `D|1|TXN10001|2026-09-11T08:15:30Z|ACC987654321|CUST001|Lokesh Sharma|INDIVIDUAL|WIRE_TRANSFER|ONLINE|USD|250000.00|Alpine Holdings AG|CHE|AML_HIGH_VALUE|Cross-border wire transfer exceeds 200k USD threshold|2026-09-11T08:30:00Z|lokesh|PENDING_REPORT`

### Trailer Record (T)
Format: `T|recordCount|totalAmount|customerCount|generatedAt|checksum`
- Normal Example: `T|6|1459900.00|6|2026-09-11T23:59:59Z|8f3a9b1c7d6e4f2a0b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a`
- Nil Report Example: `T|0|0.00|0|2026-09-11T23:59:59Z|NIL_REPORT`

---

## 3. Cryptographic Checksum & Integrity Design

1. **Detail Payload Canonical Form**: Detail records are concatenated with single newline (`\n`) separators.
2. **SHA-256 Computation**: Computed via `dw::Crypto::SHA256(vars.detailSection as Binary)`.
3. **Zero Record Rule**: When zero records qualify, checksum is explicitly `NIL_REPORT`.
4. **Storage Points**: The checksum is immutably stored in:
   - Line `T` of the regulatory CSV submission.
   - Column `checksum` in `compliance_report_runs`.
   - The human-readable executive summary `.txt`.
   - The compliance officer notification email.

---

## 4. State Machine & Recovery Workflow

```
[INIT]
  |
  v
[RUNNING] ------------(Completeness Mismatch / DB Timeout)---------> [FAILED]
  |                                                                     |
  v (Completeness Verified)                                             | (No Control Advance)
[REPORT_GENERATED] ---(Disk Full / File Collision)------------------> [FAILED]
  |                                                                     |
  v (Files Written)                                                     |
[ARCHIVED] -----------(SMTP Connectivity Failure)-------------------> [FAILED]
  |                                                                     |
  v (Email Dispatched)                                                  |
[NOTIFIED]                                                              |
  |                                                                     |
  v (Flags Marked REPORTED & Control Timestamp Advanced)                |
[SUCCESS] <-------------------------------------------------------------+
```
