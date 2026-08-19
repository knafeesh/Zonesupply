const http = require('http');

const postData = JSON.stringify({
  membershipId: 'ZS100002',
  mobile: '8168051355',
  name: 'MOHAMMAD NAFEESH',
  email: 'knafeesh2@gmail.com',
  shopName: 'clothes shop'
});

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/v1/auth/membership-login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData)
  }
};

const req = http.request(options, (res) => {
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    console.log('Status Code:', res.statusCode);
    console.log('Response Body:', body);
  });
});

req.on('error', (e) => {
  console.error('Request Error:', e);
});

req.write(postData);
req.end();
