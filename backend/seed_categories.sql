-- Seed categories and new products
-- Update existing products to 'Fashion'
UPDATE products SET category = 'Fashion' WHERE category IS NULL OR category = '';

-- Insert Grocery products
INSERT INTO products (id, name, description, "pricePerUnit", unit, "stockQuantity", category, "wholesalerId", "isAvailable")
VALUES
  (uuid_generate_v4(), 'Basmati Rice (Bulk)', 'Premium long grain basmati rice', 60.00, 'kg', 500, 'Grocery', '79a4c1b2-b967-4512-b93a-a74db1323403', true),
  (uuid_generate_v4(), 'Refined Sugar', 'High purity refined white sugar', 42.00, 'kg', 1000, 'Grocery', '79a4c1b2-b967-4512-b93a-a74db1323403', true)
ON CONFLICT DO NOTHING;

-- Insert Mobiles products
INSERT INTO products (id, name, description, "pricePerUnit", unit, "stockQuantity", category, "wholesalerId", "isAvailable")
VALUES
  (uuid_generate_v4(), 'ProPhone 14 Max', 'Latest generation 5G smartphone with 256GB storage', 45000.00, 'piece', 15, 'Mobiles', '79a4c1b2-b967-4512-b93a-a74db1323403', true),
  (uuid_generate_v4(), 'LitePhone Z', 'Budget smartphone with 5000mAh battery', 9500.00, 'piece', 40, 'Mobiles', '79a4c1b2-b967-4512-b93a-a74db1323403', true)
ON CONFLICT DO NOTHING;

-- Insert Electronics products
INSERT INTO products (id, name, description, "pricePerUnit", unit, "stockQuantity", category, "wholesalerId", "isAvailable")
VALUES
  (uuid_generate_v4(), 'LED Smart TV 43"', 'Ultra HD 4K Smart TV with Dolby Atmos', 24000.00, 'piece', 8, 'Electronics', '79a4c1b2-b967-4512-b93a-a74db1323403', true),
  (uuid_generate_v4(), 'Bluetooth Wireless Speaker', 'Portable waterproof speaker with heavy bass', 1800.00, 'piece', 50, 'Electronics', '79a4c1b2-b967-4512-b93a-a74db1323403', true)
ON CONFLICT DO NOTHING;

-- Insert Home products
INSERT INTO products (id, name, description, "pricePerUnit", unit, "stockQuantity", category, "wholesalerId", "isAvailable")
VALUES
  (uuid_generate_v4(), 'Non-Stick Cookware Set (3pc)', 'Includes frying pan, kadhai, and tawa', 1450.00, 'box', 30, 'Home', '79a4c1b2-b967-4512-b93a-a74db1323403', true),
  (uuid_generate_v4(), 'Cotton Double Bedsheet', 'King size floral print with 2 pillow covers', 650.00, 'piece', 100, 'Home', '79a4c1b2-b967-4512-b93a-a74db1323403', true)
ON CONFLICT DO NOTHING;
