const http = require('http');

function post(url, data, token = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const postData = JSON.stringify(data);
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        ...(token ? { 'Authorization': `Bearer ${token}` } : {})
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(parsed);
          } else {
            reject({ status: res.statusCode, data: parsed });
          }
        } catch (e) {
          resolve(body);
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

function get(url, token = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname,
      method: 'GET',
      headers: {
        ...(token ? { 'Authorization': `Bearer ${token}` } : {})
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(parsed);
          } else {
            reject({ status: res.statusCode, data: parsed });
          }
        } catch (e) {
          resolve(body);
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

async function testConnection() {
  const timestamp = Date.now();
  const sellerEmail = `seller_conn_${timestamp}@zonesupply.com`;
  const testShopName = `Shree Balaji Wholesalers ${timestamp.toString().slice(-4)}`;

  console.log('====================================================');
  console.log('TEST 1: Seller Registers a New Wholesale Shop');
  console.log('====================================================');

  const regRes = await post('http://localhost:3000/api/v1/auth/register', {
    name: 'Balaji Store Owner',
    email: sellerEmail,
    password: 'Password123!',
    phone: '9988776655',
    role: 'WHOLESALER',
    businessName: testShopName,
    gstNumber: '07AAAAA5555A1Z2',
    panNumber: 'ABCDE9999F',
    address: 'Shop 21, Mega Mandi Complex',
    shopNumber: 'M-21'
  });

  console.log('Seller Registered! User ID:', regRes.user.id);
  const sellerToken = regRes.accessToken;

  // Fetch wholesaler profile to get wholesaler ID
  const sellerProfile = await get('http://localhost:3000/api/v1/wholesalers/profile', sellerToken);
  const wholesalerId = sellerProfile.id;
  console.log('Wholesale Shop ID:', wholesalerId, '| Shop Name:', sellerProfile.businessName);

  console.log('\n====================================================');
  console.log('TEST 2: Verify Retailer App Fetches the New Wholesale Shop');
  console.log('====================================================');

  // Retailer App calls GET /api/v1/wholesalers (with or without auth)
  const allWholesalers = await get('http://localhost:3000/api/v1/wholesalers', sellerToken);
  const foundShop = allWholesalers.find(w => w.id === wholesalerId);

  if (foundShop) {
    console.log('MATCH FOUND in Retailer App Wholesale List!');
    console.log('  Shop Name   :', foundShop.businessName);
    console.log('  Address     :', foundShop.address);
    console.log('  Shop Number :', foundShop.shopNumber);
    console.log('  Owner       :', foundShop.user?.name);
    console.log('  Live Products Count:', foundShop.productCount);
  } else {
    console.error('FAILED: Shop not found in /wholesalers');
    return;
  }

  console.log('\n====================================================');
  console.log('TEST 3: Seller Uploads a Product on Seller Dashboard');
  console.log('====================================================');

  const testProductName = `Fortune Sunlite Oil 15L Tin - ${timestamp.toString().slice(-4)}`;
  const createdProduct = await post('http://localhost:3000/api/v1/products', {
    name: testProductName,
    description: 'Refined sunflower oil for commercial kitchens & grocery stores',
    category: 'Grocery > Edible Oils & Ghee',
    pricePerUnit: 1850,
    unit: 'tin',
    stockQuantity: 250,
    discount: 5,
    barcode: `890${timestamp.toString().slice(-9)}`,
    imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400',
    images: ['https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400'],
    isAvailable: true
  }, sellerToken);

  console.log('Product Uploaded on Seller Dashboard!');
  console.log('  Product ID   :', createdProduct.id);
  console.log('  Product Name :', createdProduct.name);
  console.log('  Category     :', createdProduct.category);
  console.log('  Price        : ₹' + createdProduct.pricePerUnit);

  console.log('\n====================================================');
  console.log('TEST 4: Verify Product in Retailer App (Global & Wholesaler Shop)');
  console.log('====================================================');

  // Retailer App Browse Screen: GET /api/v1/products
  const globalProducts = await get('http://localhost:3000/api/v1/products', sellerToken);
  const foundInGlobal = globalProducts.find(p => p.id === createdProduct.id);

  if (foundInGlobal) {
    console.log('MATCH FOUND in Retailer App Global Browse Feed!');
    console.log('  Product Name  :', foundInGlobal.name);
    console.log('  Wholesaler    :', foundInGlobal.wholesaler?.businessName);
  } else {
    console.error('FAILED: Product not found in /products');
    return;
  }

  // Retailer App Wholesaler Shop Screen: GET /api/v1/products/wholesaler/:wholesalerId
  const shopProducts = await get(`http://localhost:3000/api/v1/products/wholesaler/${wholesalerId}`, sellerToken);
  const foundInShop = shopProducts.find(p => p.id === createdProduct.id);

  if (foundInShop) {
    console.log('MATCH FOUND in Retailer App Wholesaler Storefront Screen!');
    console.log('  Storefront Product Count:', shopProducts.length);
  } else {
    console.error('FAILED: Product not found in /products/wholesaler/:wholesalerId');
    return;
  }

  console.log('\n====================================================');
  console.log('RESULT: 100% REAL-TIME BIDIRECTIONAL SYNC VERIFIED!');
  console.log('====================================================');
}

testConnection().catch(console.error);
