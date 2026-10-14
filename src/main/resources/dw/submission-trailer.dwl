%dw 2.0
output text/plain
/*
 * Generates Prescribed Regulatory Submission Trailer Record (T)
 * Format: T|recordCount|totalAmount|customerCount|generatedAt|checksum
 */
var recordCount = (vars.runMetrics.recordCount default 0) as Number
var totalAmount = (vars.runMetrics.totalAmount default 0.00) as Number as String {format: "0.00"}
var customerCount = (vars.runMetrics.customerCount default 0) as Number
var generatedAt = (vars.runContext.generatedAt as String) default (now() as String {format: "yyyy-MM-dd'T'HH:mm:ss'Z'"})
var checksum = if (recordCount == 0) "NIL_REPORT" else (vars.runMetrics.checksum default "NIL_REPORT")
---
["T", recordCount as String, totalAmount, customerCount as String, generatedAt, checksum] joinBy "|"
