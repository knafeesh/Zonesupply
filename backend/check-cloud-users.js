const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://neondb_owner:npg_9fYAtgaJWM4p@ep-winter-snow-axdhvl8n.c-4.us-east-2.aws.neon.tech/neondb?sslmode=require'
});

async function main() {
  await client.connect();
  console.log('Connected to Neon DB');

  // Check what users exist
  const users = await client.query(`SELECT email, role, "isActive" FROM "users" WHERE role IN ('ADMIN', 'WHOLESALER') LIMIT 20`);
  console.log('Existing users:', JSON.stringify(users.rows, null, 2));

  await client.end();
}

main().catch(e => console.log('ERROR:', e.message));
