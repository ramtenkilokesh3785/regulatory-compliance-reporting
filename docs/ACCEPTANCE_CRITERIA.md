# Acceptance Criteria Verification Checklist

| # | Acceptance Criterion | Verification Procedure | Status |
| :--- | :--- | :--- | :--- |
| **1** | Scheduled run extracts correct period, generates submission and summary files, archives them, and emails compliance officer. | Verified through `compliance-orchestrator-flow` end-to-end execution. | **PASS** |
| **2** | Header, detail, and trailer layouts match prescribed format and totals agree. | Formatted in `report-subflows.xml` with exact pipe `\|` delimiter and 19-field detail format. | **PASS** |
| **3** | Identical inputs and fixed generation metadata produce byte-identical submission content. | Deterministic sorting (`ORDER BY flagged_at ASC, transaction_id ASC`) guarantees canonical bytes. | **PASS** |
| **4** | Consecutive reporting periods contain no gaps or overlaps. | Strictly computed via `flagged_at >= periodStart AND flagged_at < periodEnd` from control table. | **PASS** |
| **5** | Failed runs preserve the control timestamp and can be safely retried. | Handled by `error-handling.xml` ensuring `compliance_report_control` is not updated on failure. | **PASS** |
| **6** | Nil reports are generated and notifications are sent when zero records qualify. | Tested in `test-compliance-orchestrator-nil-report`, generating `T\|0\|0.00\|0\|...\|NIL_REPORT`. | **PASS** |
| **7** | Completeness mismatches prevent submission and archival. | Validated in `validate-completeness-subflow` raising `COMPLIANCE:COMPLETENESS_MISMATCH`. | **PASS** |
| **8** | Checksum values agree with specified SHA-256 convention and archived content. | Generated via `Crypto::SHA256` on detail section and stored across files, audit DB, and emails. | **PASS** |
| **9** | Existing archives cannot be overwritten and revisions have new sequence numbers. | File connector uses `mode="CREATE_NEW"` and sequence increments per run. | **PASS** |
| **10** | Large reporting periods are processed using streaming or pagination. | `db:select` configured with `fetchSize="500"` cursor streaming. | **PASS** |
| **11** | MUnit tests cover success, nil reports, mismatches, reprocessing, and failure paths. | Full test suite implemented in `src/test/munit/` with assertions and mocks. | **PASS** |
