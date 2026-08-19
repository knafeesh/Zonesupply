const { Client } = require('pg');

async function dropSchema() {
  const client = new Client({
    host: 'localhost',
    port: 5433,
    database: 'zonesupply_db',
    user: 'zonesupply_user',
    password: 'zonesupply_pass',
  });

  try {
    await client.connect();
    console.log('Connected to DB');
    await client.query('DROP SCHEMA public CASCADE;');
    await client.query('CREATE SCHEMA public;');
    console.log('Schema dropped and recreated successfully');
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.end();
  }
}

dropSchema();
