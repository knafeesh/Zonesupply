const { Client } = require('pg');

async function main() {
  const client = new Client({
    connectionString: "postgresql://zonesupply_user:zonesupply_pass@localhost:5433/zonesupply_db"
  });
  await client.connect();

  console.log("--- USERS ---");
  const users = await client.query("SELECT id, name, email, role FROM users;");
  console.log(users.rows);

  console.log("--- WHOLESALERS ---");
  const wholesalers = await client.query("SELECT id, \"userId\", \"businessName\" FROM wholesalers;");
  console.log(wholesalers.rows);

  console.log("--- CREDIT LEDGER ---");
  const ledger = await client.query("SELECT id, \"retailerId\", \"wholesalerId\", \"creditLimit\", \"outstandingBalance\" FROM credit_ledger;");
  console.log(ledger.rows);

  console.log("--- LEDGER TRANSACTIONS ---");
  const txs = await client.query("SELECT id, \"ledgerId\", \"orderId\", type, amount, \"balanceAfter\" FROM ledger_transactions LIMIT 10;");
  console.log(txs.rows);

  await client.end();
}

main().catch(console.error);
