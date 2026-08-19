-- Fix existing retailers with null zoneId
UPDATE retailers
SET "zoneId" = (SELECT id FROM zones LIMIT 1)
WHERE "zoneId" IS NULL;

-- Confirm
SELECT r.id, r."shopName", r."zoneId", z.name as zone FROM retailers r LEFT JOIN zones z ON z.id = r."zoneId";
