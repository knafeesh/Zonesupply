const { Client } = require('pg');

async function main() {
  const client = new Client({
    connectionString: "postgresql://zonesupply_user:zonesupply_pass@localhost:5433/zonesupply_db"
  });
  await client.connect();

  console.log("=== ZONES ===");
  const zones = await client.query('SELECT id, name, city, pincode, "centerLat", "centerLng", "radiusKm" FROM zones;');
  console.log(zones.rows);

  console.log("=== RETAILERS ===");
  const retailers = await client.query('SELECT id, "shopName", city, latitude, longitude, "zoneId" FROM retailers;');
  console.log(retailers.rows);

  console.log("=== WHOLESALERS ===");
  const wholesalers = await client.query('SELECT id, "businessName", city, latitude, longitude FROM wholesalers;');
  console.log(wholesalers.rows);

  await client.end();
}

main().catch(console.error);
