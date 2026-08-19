SELECT
  r.id as retailer_id,
  r."shopName",
  r."zoneId",
  w.id as wholesaler_id,
  cl."creditLimit",
  cl."outstandingBalance"
FROM retailers r
LEFT JOIN credit_ledger cl ON cl."retailerId" = r.id
LEFT JOIN wholesalers w ON w.id = cl."wholesalerId";
