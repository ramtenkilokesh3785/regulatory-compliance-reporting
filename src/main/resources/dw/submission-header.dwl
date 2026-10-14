%dw 2.0
output text/plain
/*
 * Generates Prescribed Regulatory Submission Header Record (H)
 * Format: H|entityCode|entityName|reportType|periodDate|generatedAt|sequenceNumber|currency
 */
fun sanitize(val: Any) = 
  if (val == null) "" 
  else (val as String replace "|" with "-" replace "\n" with " " replace "\r" with "")

var entityCode = sanitize(vars.runContext.entityCode)
var entityName = sanitize(vars.runContext.entityName)
var reportType = sanitize(vars.runContext.reportType)
var periodDate = (vars.runContext.periodEnd[0 to 9]) default (now() as String {format: "yyyy-MM-dd"})
var generatedAt = (vars.runContext.generatedAt as String) default (now() as String {format: "yyyy-MM-dd'T'HH:mm:ss'Z'"})
var sequenceNumber = (vars.runContext.sequenceNumber as Number) as String {format: "000"}
var currency = sanitize(vars.runContext.currency default "USD")
---
["H", entityCode, entityName, reportType, periodDate, generatedAt, sequenceNumber, currency] joinBy "|"
