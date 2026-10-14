%dw 2.0
output text/plain
/*
 * Generates HTML Notification Email for Compliance Officers
 */
fun formatAmount(amt: Any) = 
  if (amt == null) "0.00"
  else (amt as Number as String {format: "#,##0.00"})

var runCtx = vars.runContext default {}
var metrics = vars.runMetrics default {}
var volAnalysis = vars.volumeAnalysis default {}
var flagGroups = (vars.extractedRecords default []) groupBy ((item) -> item.flag_code default item.flagCode default "UNKNOWN")
var isNil = (metrics.recordCount default 0) == 0
var hasAlert = volAnalysis.hasDeviationAlert default false
var isSecureLink = (vars.notificationMode default "ATTACHMENT") == "SECURE_LINK"
---
"<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #2D3748; background-color: #F7FAFC; margin: 0; padding: 20px; }
  .container { max-width: 680px; margin: 0 auto; background: #FFFFFF; border-radius: 8px; border: 1px solid #E2E8F0; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
  .header { background: #1A365D; color: #FFFFFF; padding: 24px; text-align: left; }
  .header h1 { margin: 0; font-size: 20px; font-weight: 600; }
  .header p { margin: 4px 0 0; font-size: 13px; color: #CBD5E0; }
  .badge { display: inline-block; padding: 4px 10px; border-radius: 4px; font-size: 12px; font-weight: bold; }
  .badge-success { background: #C6F6D5; color: #22543D; }
  .badge-warning { background: #FEEBC8; color: #7B341E; }
  .badge-info { background: #BEE3F8; color: #2A4365; }
  .content { padding: 24px; }
  .section-title { font-size: 14px; font-weight: bold; text-transform: uppercase; color: #4A5568; margin-top: 20px; margin-bottom: 10px; border-bottom: 2px solid #EDF2F7; padding-bottom: 4px; }
  table { width: 100%; border-collapse: collapse; margin-bottom: 15px; font-size: 13px; }
  th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #E2E8F0; }
  th { background: #EDF2F7; color: #4A5568; font-weight: 600; }
  .highlight { background: #F7FAFC; font-weight: bold; }
  .alert-box { background: #FFF5F5; border-left: 4px solid #E53E3E; padding: 12px 16px; margin: 15px 0; border-radius: 4px; color: #9B2C2C; font-size: 13px; }
  .secure-box { background: #EBF8FF; border: 1px dashed #3182CE; padding: 16px; margin: 15px 0; border-radius: 6px; text-align: center; }
  .secure-link { display: inline-block; background: #2B6CB0; color: #FFFFFF; padding: 10px 20px; text-decoration: none; border-radius: 4px; font-weight: 600; margin-top: 8px; }
  .footer { background: #EDF2F7; padding: 16px 24px; font-size: 11px; color: #718096; text-align: center; }
</style>
</head>
<body>
<div class='container'>
  <div class='header'>
    <h1>Regulatory Compliance Reporting Notification</h1>
    <p>Entity: " ++ (runCtx.entityName default "Apex Global Banking") ++ " (" ++ (runCtx.entityCode default "ENT0091") ++ ") | Report: " ++ (runCtx.reportType default "STR") ++ "</p>
  </div>
  <div class='content'>
    <p>A scheduled regulatory compliance report has been generated, validated, and archived successfully.</p>
    
    " ++ (if (hasAlert) 
      "<div class='alert-box'><strong>Volume Deviation Warning:</strong> Reporting volume deviates by " ++ (volAnalysis.recordDeviationPct default "0%") ++ " from 30-day baseline average (" ++ (volAnalysis.avgRecordCount default "0") ++ " expected records).</div>"
      else "") ++ "

    <div class='section-title'>Execution Summary</div>
    <table>
      <tr><th>Run ID</th><td>" ++ (runCtx.runId default "N/A") ++ "</td></tr>
      <tr><th>Reporting Period</th><td>" ++ (runCtx.periodStart as String) ++ " &mdash; " ++ (runCtx.periodEnd as String) ++ "</td></tr>
      <tr><th>Sequence / Revision</th><td>Seq #" ++ (runCtx.sequenceNumber as Number as String {format: "000"}) ++ (if (runCtx.isRevision default false) " <span class='badge badge-warning'>REVISION</span>" else " <span class='badge badge-info'>ORIGINAL</span>") ++ "</td></tr>
      <tr><th>Completeness Status</th><td><span class='badge badge-success'>" ++ (metrics.completenessResult default "PASS") ++ "</span> (Record counts and monetary totals verified against independent aggregate query)</td></tr>
      <tr><th>Nil Report Declaration</th><td>" ++ (if (isNil) "<span class='badge badge-info'>YES (NIL REPORT)</span>" else "NO") ++ "</td></tr>
    </table>

    <div class='section-title'>Transaction Totals</div>
    <table>
      <tr><th>Metric</th><th>Reported Value</th></tr>
      <tr><td>Flagged Record Count</td><td class='highlight'>" ++ ((metrics.recordCount default 0) as String) ++ "</td></tr>
      <tr><td>Total Value (" ++ (runCtx.currency default "USD") ++ ")</td><td class='highlight'>" ++ (runCtx.currency default "USD") ++ " " ++ formatAmount(metrics.totalAmount default 0.00) ++ "</td></tr>
      <tr><td>Distinct Customers</td><td class='highlight'>" ++ ((metrics.customerCount default 0) as String) ++ "</td></tr>
    </table>

    <div class='section-title'>Compliance Flag Breakdown</div>
    <table>
      <tr><th>Flag Code</th><th>Count</th><th>Total Amount (" ++ (runCtx.currency default "USD") ++ ")</th></tr>
      " ++ (if (isNil) "<tr><td colspan='3'>Zero flagged records in period</td></tr>"
           else (flagGroups pluck ((records, flagCode) ->
             "<tr><td><strong>" ++ (flagCode as String) ++ "</strong></td><td>" ++ (sizeOf(records) as String) ++ "</td><td>" ++ formatAmount(sum(records map ((r) -> (r.amount default 0) as Number))) ++ "</td></tr>"
           )) joinBy "") ++ "
    </table>

    <div class='section-title'>Integrity & Storage</div>
    <table>
      <tr><th>Submission File</th><td>" ++ (vars.submissionFilename default "N/A") ++ "</td></tr>
      <tr><th>SHA-256 Checksum</th><td><code>" ++ (metrics.checksum default "NIL_REPORT") ++ "</code></td></tr>
      <tr><th>Archive Location</th><td><code>" ++ (vars.archiveSubmissionFilePath default "N/A") ++ "</code></td></tr>
    </table>

    " ++ (if (isSecureLink)
      "<div class='secure-box'>
        <p><strong>Attachment Size Limit Exceeded:</strong> Report files exceed the email gateway limit (" ++ (vars.maxAttachmentSizeFormatted default "10 MB") ++ "). Files have been placed in the secure compliance repository.</p>
        <a href='" ++ (vars.secureDownloadUrl default "https://compliance.internal.bank/portal/reports/download?token=" ++ runCtx.runId) ++ "' class='secure-link'>Access Secure Compliance Portal</a>
      </div>"
      else
      "<p style='font-size:12px; color:#718096;'><em>The regulatory submission CSV and executive summary files are attached to this email.</em></p>"
    ) ++ "
  </div>
  <div class='footer'>
    This is an automated regulatory compliance dispatch from MuleSoft Regulatory Reporting Engine. Correlation ID: " ++ (runCtx.correlationId default "N/A") ++ "
  </div>
</div>
</body>
</html>"
