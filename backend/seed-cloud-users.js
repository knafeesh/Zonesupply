const { Client } = require('pg');
const bcrypt = require('bcrypt');

const client = new Client({
  connectionString: 'postgresql://neondb_owner:npg_9fYAtgaJWM4p@ep-winter-snow-axdhvl8n.c-4.us-east-2.aws.neon.tech/neondb?sslmode=require'
});

async function main() {
  await client.connect();
  console.log('Connected to Neon DB');

  // Check tables first
  const tables = await client.query(`SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name`);
  console.log('Tables:', tables.rows.map(r => r.table_name).join(', '));

  // Check users columns
  const cols = await client.query(`SELECT column_name FROM information_schema.columns WHERE table_name = 'users' ORDER BY ordinal_position`);
  console.log('Users columns:', cols.rows.map(r => r.column_name).join(', '));

  // Hash passwords
  const adminHash = await bcrypt.hash('admin123', 10);
  const sellerHash = await bcrypt.hash('password123', 10);

  // Seed admin user
  await client.query(`
    INSERT INTO users (id, email, "passwordHash", name, phone, role, "isActive", "createdAt", "updatedAt")
    VALUES (
      gen_random_uuid(),
      'admin@zonesupply.com',
      $1,
      'Super Admin',
      '9999999999',
      'ADMIN',
      true,
      NOW(),
      NOW()
    )
    ON CONFLICT (email) DO UPDATE SET
      "passwordHash" = $1,
      "isActive" = true,
      "updatedAt" = NOW()
  `, [adminHash]);
  console.log('✅ Admin user seeded: admin@zonesupply.com / admin123');

  // Seed wholesaler/seller user
  await client.query(`
    INSERT INTO users (id, email, "passwordHash", name, phone, role, "isActive", "createdAt", "updatedAt")
    VALUES (
      gen_random_uuid(),
      '23103116004mn@gmail.com',
      $1,
      'MN Seller',
      '9888888888',
      'WHOLESALER',
      true,
      NOW(),
      NOW()
    )
    ON CONFLICT (email) DO UPDATE SET
      "passwordHash" = $1,
      "isActive" = true,
      "updatedAt" = NOW()
  `, [sellerHash]);
  console.log('✅ Seller user seeded: 23103116004mn@gmail.com / password123');

  // Verify
  const users = await client.query(`SELECT email, role, "isActive" FROM users`);
  console.log('All users:', JSON.stringify(users.rows, null, 2));

  await client.end();
}

main().catch(e => { console.log('ERROR:', e.message); client.end(); });
