-- 1. Insert or Update Admin user (admin@zonesupply.com / Admin@123)
INSERT INTO users (id, email, "passwordHash", name, role, "isActive", "createdAt", "updatedAt")
VALUES (
  'a0000000-0000-0000-0000-000000000001',
  'admin@zonesupply.com',
  '$2b$10$NmDg1HcQjHfKz20Vin32EeTgmWmwiAKsea2t0U73S0GG88yAlfTQq',
  'Super Admin',
  'ADMIN',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (email) DO UPDATE 
SET "passwordHash" = '$2b$10$NmDg1HcQjHfKz20Vin32EeTgmWmwiAKsea2t0U73S0GG88yAlfTQq',
    role = 'ADMIN',
    "isActive" = true;

-- 2. Insert or Update Seller user (seller@zonesupply.com / Seller@123)
INSERT INTO users (id, email, "passwordHash", name, phone, role, "isActive", "createdAt", "updatedAt")
VALUES (
  'b0000000-0000-0000-0000-000000000002',
  'seller@zonesupply.com',
  '$2b$10$jKq0BDBJYFYuT27ZPDP7Ze0RCGdcCf0PpKQxmI35xOGR1uijL0dt.',
  'Zone Seller Admin',
  '9876543210',
  'WHOLESALER',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (email) DO UPDATE 
SET "passwordHash" = '$2b$10$jKq0BDBJYFYuT27ZPDP7Ze0RCGdcCf0PpKQxmI35xOGR1uijL0dt.',
    role = 'WHOLESALER',
    "isActive" = true;

-- 3. Ensure Wholesaler Profile for seller@zonesupply.com
INSERT INTO wholesalers (id, "userId", "businessName", "gstNumber", "panNumber", address, "shopNumber", latitude, longitude, "createdAt", "updatedAt")
VALUES (
  'c0000000-0000-0000-0000-000000000003',
  'b0000000-0000-0000-0000-000000000002',
  'Zone Supply Wholesale Hub',
  '07AAAAA1234A1Z5',
  'ABCDE1234F',
  'Plot 45, Main Wholesale Market, Sector 18, Gurugram',
  'Shop No. 101',
  28.4595,
  77.0266,
  NOW(),
  NOW()
)
ON CONFLICT ("userId") DO UPDATE
SET "businessName" = 'Zone Supply Wholesale Hub',
    "gstNumber" = '07AAAAA1234A1Z5',
    "panNumber" = 'ABCDE1234F',
    address = 'Plot 45, Main Wholesale Market, Sector 18, Gurugram',
    "shopNumber" = 'Shop No. 101',
    latitude = 28.4595,
    longitude = 77.0266;
