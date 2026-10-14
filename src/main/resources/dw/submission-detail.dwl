%dw 2.0
output text/plain
/*
 * Generates Prescribed Regulatory Submission Detail Records (D)
 * Deterministically sorted by flagged_at ASC, transaction_id ASC
 * Format: D|serial|transactionId|transactionDateTime|accountNumber|customerId|customerName|customerType|transactionType|channel|currency|amount|counterpartyName|counterpartyCountry|flagCode|flagReason|flaggedAt|reviewedBy|reviewStatus
 */
fun sanitize(val: Any) = 
  if (val == null) "" 
  else (val as String replace "|" with "-" replace "\n" with " " replace "\r" with "")

fun formatTimestamp(ts: Any) = 
  if (ts == null) ""
  else (ts as DateTime as String {format: "yyyy-MM-dd'T'HH:mm:ss'Z'"}) default (ts as String)

fun formatAmount(amt: Any) = 
  if (amt == null) "0.00"
  else (amt as Number as String {format: "0.00"})

var records = (payload default []) orderBy (item) -> ((item.flagged_at default item.flaggedAt default "") ++ "_" ++ (item.transaction_id default item.transactionId default ""))
---
if (isEmpty(records)) ""
else
  (records map ((item, index) -> 
    [
      "D",
      (index + 1) as String,
      sanitize(item.transaction_id default item.transactionId),
      formatTimestamp(item.transaction_timestamp default item.transactionTimestamp),
      sanitize(item.account_number default item.accountNumber),
      sanitize(item.customer_id default item.customerId),
      sanitize(item.customer_name default item.customerName),
      sanitize(item.customer_type default item.customerType),
      sanitize(item.transaction_type default item.transactionType),
      sanitize(item.channel),
      sanitize(item.currency default vars.runContext.currency default "USD"),
      formatAmount(item.amount),
      sanitize(item.counterparty_name default item.counterpartyName),
      sanitize(item.counterparty_country default item.counterpartyCountry),
      sanitize(item.flag_code default item.flagCode),
      sanitize(item.flag_reason default item.flagReason),
      formatTimestamp(item.flagged_at default item.flaggedAt),
      sanitize(item.reviewer default item.reviewedBy),
      sanitize(item.review_status default item.reviewStatus)
    ] joinBy "|"
  )) joinBy "\n"
