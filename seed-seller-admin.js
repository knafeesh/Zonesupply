const { Client } = require('pg');
const bcrypt = require('bcryptjs');

async function seed() {
  const client = new Client({
    host: 'localhost',
    port: 5433,
    user: 'zonesupply_user',
    password: 'zonesupply_pass',
    database: 'zonesupply_db',
  });

  await client.connect();
  console.log('Connected to zonesupply_db');

  const adminHash = await bcrypt.hash('Admin@123', 10);
  const sellerHash = await bcrypt.hash('Seller@123', 10);

  // 1. Ensure Admin User
  const adminRes = await client.query('SELECT id FROM users WHERE email = $1', ['admin@zonesupply.com']);
  if (adminRes.rows.length === 0) {
    await client.query(`
      INSERT INTO users (id, email, "passwordHash", name, role, "isActive", "createdAt", "updatedAt")
      VALUES (gen_random_uuid(), 'admin@zonesupply.com', $1, 'Super Admin', 'ADMIN', true, NOW(), NOW())
    `, [adminHash]);
    console.log('Created Admin: admin@zonesupply.com / Admin@123');
  } else {
    await client.query(`
      UPDATE users SET "passwordHash" = $1, role = 'ADMIN', "isActive" = true WHERE email = 'admin@zonesupply.com'
    `, [adminHash]);
    console.log('Updated Admin password: admin@zonesupply.com / Admin@123');
  }

  // 2. Ensure Demo Seller User
  const sellerRes = await client.query('SELECT id FROM users WHERE email = $1', ['seller@zonesupply.com']);
  let sellerUserId;
  if (sellerRes.rows.length === 0) {
    const insertRes = await client.query(`
      INSERT INTO users (id, email, "passwordHash", name, phone, role, "isActive", "createdAt", "updatedAt")
      VALUES (gen_random_uuid(), 'seller@zonesupply.com', $1, 'Zone Seller Admin', '9876543210', 'WHOLESALER', true, NOW(), NOW())
      RETURNING id
    `, [sellerHash]);
    sellerUserId = insertRes.rows[0].id;
    console.log('Created Seller: seller@zonesupply.com / Seller@123');
  } else {
    sellerUserId = sellerRes.rows[0].id;
    await client.query(`
      UPDATE users SET "passwordHash" = $1, role = 'WHOLESALER', "isActive" = true WHERE email = 'seller@zonesupply.com'
    `, [sellerHash]);
    console.log('Updated Seller password: seller@zonesupply.com / Seller@123');
  }

  // Ensure wholesaler profile for seller
  const wRes = await client.query('SELECT id FROM wholesalers WHERE "userId" = $1', [sellerUserId]);
  if (wRes.rows.length === 0) {
    await client.query(`
      INSERT INTO wholesalers (id, "userId", "businessName", "gstNumber", "panNumber", address, "shopNumber", "createdAt", "updatedAt")
      VALUES (gen_random_uuid(), $1, 'Zone Supply Wholesale Hub', '07AAAAA1234A1Z5', 'ABCDE1234F', 'Plot 45, Main Wholesale Market, Sector 18', 'Shop No. 101', NOW(), NOW())
    `, [sellerUserId]);
    console.log('Created Wholesaler profile for seller@zonesupply.com');
  }

  await client.end();
  console.log('Seeding complete!');
}

seed().catch(console.error);
