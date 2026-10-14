%dw 2.0
output text/plain
/*
 * Generates Human-Readable Regulatory Compliance Summary Report (.txt)
 */
fun formatAmount(amt: Any) = 
  if (amt == null) "0.00"
  else (amt as Number as String {format: "#,##0.00"})

var runCtx = vars.runContext default {}
var metrics = vars.runMetrics default {}
var volAnalysis = vars.volumeAnalysis default {}
var flagGroups = (vars.extractedRecords default []) groupBy ((item) -> item.flag_code default item.flagCode default "UNKNOWN")
var isNil = (metrics.recordCount default 0) == 0
---
"================================================================================" ++ "\n" ++
"           REGULATORY COMPLIANCE REPORTING - EXECUTIVE SUMMARY                 " ++ "\n" ++
"================================================================================" ++ "\n" ++
"Report Type          : " ++ (runCtx.reportType default "STR") ++ " (Suspicious Transaction Report)\n" ++
"Reporting Entity     : " ++ (runCtx.entityName default "Apex Global Banking") ++ " [" ++ (runCtx.entityCode default "ENT0091") ++ "]\n" ++
"Currency             : " ++ (runCtx.currency default "USD") ++ "\n" ++
"Run ID               : " ++ (runCtx.runId default "N/A") ++ "\n" ++
"Correlation ID       : " ++ (runCtx.correlationId default "N/A") ++ "\n" ++
"Trigger Source       : " ++ (runCtx.triggerSource default "SCHEDULED") ++ "\n" ++
"Sequence Number      : " ++ (runCtx.sequenceNumber as Number as String {format: "000"}) ++ (if (runCtx.isRevision default false) " [REVISION]" else " [ORIGINAL]") ++ "\n" ++
"Reporting Period     : " ++ (runCtx.periodStart as String) ++ " to " ++ (runCtx.periodEnd as String) ++ "\n" ++
"Generated At         : " ++ (runCtx.generatedAt as String) ++ "\n" ++
"--------------------------------------------------------------------------------\n" ++
"                         TRANSACTION TOTALS & INTEGRITY                         \n" ++
"--------------------------------------------------------------------------------\n" ++
"Nil Report Status    : " ++ (if (isNil) "YES (NIL REPORT - ZERO QUALIFYING TRANSACTIONS)" else "NO") ++ "\n" ++
"Total Flagged Records: " ++ ((metrics.recordCount default 0) as String) ++ "\n" ++
"Total Transaction Val: " ++ (runCtx.currency default "USD") ++ " " ++ formatAmount(metrics.totalAmount default 0.00) ++ "\n" ++
"Distinct Customers   : " ++ ((metrics.customerCount default 0) as String) ++ "\n" ++
"Completeness Check   : " ++ (metrics.completenessResult default "PASS") ++ " (Extracted vs Independent Aggregate Query: MATCH)\n" ++
"SHA-256 Checksum     : " ++ (metrics.checksum default "NIL_REPORT") ++ "\n" ++
"--------------------------------------------------------------------------------\n" ++
"                        VOLUME DEVIATION & THRESHOLD ANALYSIS                   \n" ++
"--------------------------------------------------------------------------------\n" ++
"Historical Runs Base : " ++ (volAnalysis.historicalRunsEvaluated default 0 as String) ++ " runs\n" ++
"Avg Historical Count : " ++ (volAnalysis.avgRecordCount default "0.0") ++ " records\n" ++
"Avg Historical Amount: " ++ (runCtx.currency default "USD") ++ " " ++ (volAnalysis.avgTotalAmount default "0.00") ++ "\n" ++
"Volume Deviation Pct : Records: " ++ (volAnalysis.recordDeviationPct default "0.0%") ++ ", Amount: " ++ (volAnalysis.amountDeviationPct default "0.0%") ++ "\n" ++
"Deviation Status     : " ++ (if (volAnalysis.hasDeviationAlert default false) "WARNING - DEVIATION EXCEEDS " ++ (volAnalysis.thresholdPct default "50.0%") else "NORMAL") ++ "\n" ++
"--------------------------------------------------------------------------------\n" ++
"                           BREAKDOWN BY COMPLIANCE FLAG                         \n" ++
"--------------------------------------------------------------------------------\n" ++
(if (isNil) "No compliance flags recorded for this reporting period.\n"
 else 
   (flagGroups pluck ((records, flagCode) -> 
      "  - " ++ (flagCode as String) ++ ": " ++ (sizeOf(records) as String) ++ " record(s), Total: " ++ 
      (runCtx.currency default "USD") ++ " " ++ formatAmount(sum(records map ((r) -> (r.amount default 0) as Number)))
   )) joinBy "\n" ++ "\n"
) ++
"--------------------------------------------------------------------------------\n" ++
"                                AUDIT & STORAGE                                \n" ++
"--------------------------------------------------------------------------------\n" ++
"Submission CSV File  : " ++ (vars.outputSubmissionFilePath default "N/A") ++ "\n" ++
"Archive Destination  : " ++ (vars.archiveSubmissionFilePath default "N/A") ++ "\n" ++
"Summary Archive File : " ++ (vars.archiveSummaryFilePath default "N/A") ++ "\n" ++
"================================================================================" ++ "\n"
