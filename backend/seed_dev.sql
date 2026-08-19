-- Zonesupply Dev Seed v2 (correct zones schema)

-- 1. Create zone
INSERT INTO zones (id, name, city, pincode, "centerLat", "centerLng", "radiusKm", "createdAt", "updatedAt")
SELECT
  uuid_generate_v4(),
  'Zone-South-BLR',
  'Bangalore',
  '560001',
  12.934533,
  77.616500,
  5.00,
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM zones LIMIT 1);

-- 2. Assign all retailers with NULL zoneId to the first zone
UPDATE retailers
SET "zoneId" = (SELECT id FROM zones LIMIT 1)
WHERE "zoneId" IS NULL;

-- 3. Create credit_ledger entries for every retailer+wholesaler pair
INSERT INTO credit_ledger ("retailerId", "wholesalerId", "creditLimit", "outstandingBalance", "updatedAt")
SELECT
  r.id,
  w.id,
  50000.00,
  0.00,
  now()
FROM retailers r
CROSS JOIN wholesalers w
WHERE NOT EXISTS (
  SELECT 1 FROM credit_ledger cl
  WHERE cl."retailerId" = r.id AND cl."wholesalerId" = w.id
);

-- 4. Verify final state
SELECT 'zones' as tbl, COUNT(*) as cnt FROM zones
UNION ALL SELECT 'retailers', COUNT(*) FROM retailers
UNION ALL SELECT 'wholesalers', COUNT(*) FROM wholesalers
UNION ALL SELECT 'credit_ledger', COUNT(*) FROM credit_ledger
UNION ALL SELECT 'products', COUNT(*) FROM products;

-- 5. Show retailer zone assignment
SELECT r.id, u.email, r."zoneId", z.name as zone_name
FROM retailers r
JOIN users u ON u.id = r."userId"
LEFT JOIN zones z ON z.id = r."zoneId";
