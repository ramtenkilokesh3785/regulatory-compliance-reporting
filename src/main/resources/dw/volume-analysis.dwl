%dw 2.0
output application/json
/*
 * Computes Trailing Historical Average and Volume Deviation
 */
var history = vars.historicalRuns default []
var validHistory = history filter (item) -> (item.run_status == "SUCCESS" or item.runStatus == "SUCCESS")
var historyCount = sizeOf(validHistory)

var avgRecordCount = if (historyCount > 0) 
    (sum(validHistory map ((item) -> (item.record_count default item.recordCount default 0) as Number)) / historyCount)
  else 0.0

var avgTotalAmount = if (historyCount > 0) 
    (sum(validHistory map ((item) -> (item.total_amount default item.totalAmount default 0.00) as Number)) / historyCount)
  else 0.00

var currentRecords = (vars.runMetrics.recordCount default 0) as Number
var currentAmount = (vars.runMetrics.totalAmount default 0.00) as Number

var recordDeviationPct = if (avgRecordCount > 0)
    (((currentRecords - avgRecordCount) / avgRecordCount) * 100)
  else 0.0

var amountDeviationPct = if (avgTotalAmount > 0)
    (((currentAmount - avgTotalAmount) / avgTotalAmount) * 100)
  else 0.0

var thresholdPct = (vars.deviationThresholdPct default 50.0) as Number
var hasDeviationAlert = if (historyCount > 0)
    (abs(recordDeviationPct) >= thresholdPct or abs(amountDeviationPct) >= thresholdPct)
  else false
---
{
  historicalRunsEvaluated: historyCount,
  avgRecordCount: avgRecordCount as String {format: "0.0"},
  avgTotalAmount: avgTotalAmount as String {format: "0.00"},
  currentRecordCount: currentRecords,
  currentTotalAmount: currentAmount as String {format: "0.00"},
  recordDeviationPct: (if (recordDeviationPct > 0) "+" else "") ++ (recordDeviationPct as String {format: "0.0"}) ++ "%",
  amountDeviationPct: (if (amountDeviationPct > 0) "+" else "") ++ (amountDeviationPct as String {format: "0.0"}) ++ "%",
  thresholdPct: thresholdPct as String {format: "0.0"} ++ "%",
  hasDeviationAlert: hasDeviationAlert,
  deviationSeverity: if (!hasDeviationAlert) "NORMAL"
                     else if (abs(recordDeviationPct) > 100 or abs(amountDeviationPct) > 100) "HIGH_DEVIATION"
                     else "MODERATE_DEVIATION"
}
