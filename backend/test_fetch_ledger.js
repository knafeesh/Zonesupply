const crypto = require('crypto');

const secret = 'your_super_secret_jwt_key_change_this_in_production';
const payload = {
  sub: 'ae428c1f-2b59-4ac8-aa95-cc15d9b11c76', // Aneesh's userId
  email: 'knafeesh0786@gmail.com',
  role: 'WHOLESALER'
};

const header = { alg: 'HS256', typ: 'JWT' };
const encodedHeader = Buffer.from(JSON.stringify(header)).toString('base64url');
const encodedPayload = Buffer.from(JSON.stringify(payload)).toString('base64url');

const signature = crypto
  .createHmac('sha256', secret)
  .update(`${encodedHeader}.${encodedPayload}`)
  .digest('base64url');

const token = `${encodedHeader}.${encodedPayload}.${signature}`;

async function test() {
  const baseUrl = 'http://localhost:3000/api/v1';

  const endpoints = [
    '/credit-ledger/wholesaler/outstanding',
    '/credit-ledger/wholesaler/transactions'
  ];

  for (const endpoint of endpoints) {
    try {
      const res = await fetch(`${baseUrl}${endpoint}`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      const data = await res.json();
      console.log(`Endpoint ${endpoint} status:`, res.status);
      console.log(`Endpoint ${endpoint} response:`, JSON.stringify(data, null, 2));
    } catch (e) {
      console.error(`Error fetching ${endpoint}:`, e.message);
    }
  }
}

test();
