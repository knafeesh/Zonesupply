const { Client } = require('pg');

async function main() {
  const client = new Client({
    connectionString: "postgresql://zonesupply_user:zonesupply_pass@localhost:5433/zonesupply_db"
  });
  await client.connect();

  console.log("Querying table names...");
  const tablesRes = await client.query("SELECT table_name FROM information_schema.tables WHERE table_schema='public';");
  const allTables = tablesRes.rows.map(r => r.table_name);
  console.log("All tables:", allTables);

  const targets = ['order_items', 'orders', 'batches', 'jobs', 'credit_ledger', 'ledger_transactions', 'favorites', 'favorite_wholesaler', 'favorite_wholesalers'];
  const tablesToTruncate = allTables.filter(t => targets.includes(t) || t.includes('order') || t.includes('delivery') || t.includes('ledger') || t.includes('favorite'));
  
  if (tablesToTruncate.length > 0) {
    const truncateQuery = `TRUNCATE TABLE ${tablesToTruncate.map(t => `"${t}"`).join(', ')} CASCADE;`;
    console.log("Executing truncate query:", truncateQuery);
    await client.query(truncateQuery);
    console.log("Truncated tables successfully.");
  }

  console.log("Fetching wholesalers to delete...");
  const toDeleteRes = await client.query("SELECT \"userId\", \"businessName\" FROM wholesalers WHERE \"businessName\" NOT ILIKE '%nafeesh%';");
  console.log("Wholesalers to delete:", toDeleteRes.rows);
  
  const userIds = toDeleteRes.rows.map(r => r.userId);
  if (userIds.length > 0) {
    const placeholders = userIds.map((_, i) => `$${i + 1}`).join(',');
    const delRes = await client.query(`DELETE FROM users WHERE id IN (${placeholders});`, userIds);
    console.log(`Successfully deleted ${delRes.rowCount} other wholesale shop users.`);
  } else {
    console.log("No other wholesale shops found to delete.");
  }

  await client.end();
}

main().catch(console.error);
