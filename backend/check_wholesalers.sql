SELECT u.email, w.id FROM users u LEFT JOIN wholesalers w ON w."userId" = u.id WHERE u.role = 'WHOLESALER';
