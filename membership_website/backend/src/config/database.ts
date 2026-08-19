import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const isProduction = process.env.NODE_ENV === 'production' || !!process.env.RENDER || !!process.env.DATABASE_URL;

const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.DATABASE_URL.includes('localhost') ? false : { rejectUnauthorized: false },
      max: 10,
      idleTimeoutMillis: 60000,
      connectionTimeoutMillis: 10000,
    })
  : new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: Number(process.env.DB_PORT) || 5433,
      user: process.env.DB_USER || 'zonesupply_user',
      password: process.env.DB_PASSWORD || 'zonesupply_pass',
      database: process.env.DB_NAME || 'zonesupply_membership',
      max: 10,
      idleTimeoutMillis: 60000,
      connectionTimeoutMillis: 10000,
      keepAlive: true,
      keepAliveInitialDelayMillis: 10000,
    });

export const initDatabase = async (): Promise<void> => {
  try {
    // ENUM Types
    await pool.query(`
      DO $$ BEGIN
        CREATE TYPE business_type_enum AS ENUM (
          'grocery', 'pharmacy', 'electronics', 'clothing',
          'restaurant', 'hardware', 'cosmetics', 'stationery', 'other'
        );
      EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    `);
    await pool.query(`
      DO $$ BEGIN
        CREATE TYPE application_status AS ENUM ('pending', 'approved', 'rejected');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    `);
    await pool.query(`
      DO $$ BEGIN
        CREATE TYPE doc_type_enum AS ENUM ('aadhaar', 'pan', 'shop_photo', 'gst_cert');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    `);
    await pool.query(`
      DO $$ BEGIN
        CREATE TYPE membership_status_enum AS ENUM ('active', 'suspended');
      EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    `);

    // Tables
    await pool.query(`
      CREATE TABLE IF NOT EXISTS admin (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS applications (
        id SERIAL PRIMARY KEY,
        application_id VARCHAR(20) NOT NULL UNIQUE,
        full_name VARCHAR(100) NOT NULL,
        mobile VARCHAR(10) NOT NULL UNIQUE,
        email VARCHAR(100) NOT NULL,
        shop_name VARCHAR(150) NOT NULL,
        business_type business_type_enum NOT NULL,
        gst_number VARCHAR(20) DEFAULT NULL,
        address TEXT NOT NULL,
        state VARCHAR(50) NOT NULL,
        city VARCHAR(50) NOT NULL,
        pincode VARCHAR(6) NOT NULL,
        status application_status DEFAULT 'pending',
        rejection_reason TEXT DEFAULT NULL,
        terms_accepted BOOLEAN NOT NULL DEFAULT FALSE,
        ip_address VARCHAR(45) DEFAULT NULL,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS documents (
        id SERIAL PRIMARY KEY,
        application_id VARCHAR(20) NOT NULL REFERENCES applications(application_id) ON DELETE CASCADE,
        doc_type doc_type_enum NOT NULL,
        file_name VARCHAR(255) NOT NULL,
        file_path VARCHAR(500) NOT NULL,
        file_size INTEGER NOT NULL,
        mime_type VARCHAR(100) NOT NULL,
        uploaded_at TIMESTAMP DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS memberships (
        id SERIAL PRIMARY KEY,
        membership_id VARCHAR(20) NOT NULL UNIQUE,
        application_id VARCHAR(20) NOT NULL UNIQUE REFERENCES applications(application_id) ON DELETE CASCADE,
        retailer_name VARCHAR(100) NOT NULL,
        shop_name VARCHAR(150) NOT NULL,
        mobile VARCHAR(10) NOT NULL,
        email VARCHAR(100) NOT NULL,
        city VARCHAR(50) NOT NULL,
        state VARCHAR(50) NOT NULL,
        membership_status membership_status_enum DEFAULT 'active',
        approved_by INTEGER DEFAULT NULL REFERENCES admin(id),
        approved_at TIMESTAMP DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS retailers (
        id SERIAL PRIMARY KEY,
        membership_id VARCHAR(20) NOT NULL UNIQUE REFERENCES memberships(membership_id) ON DELETE CASCADE,
        application_id VARCHAR(20) NOT NULL UNIQUE,
        full_name VARCHAR(100) NOT NULL,
        shop_name VARCHAR(150) NOT NULL,
        mobile VARCHAR(10) NOT NULL,
        email VARCHAR(100) NOT NULL,
        business_type VARCHAR(50) NOT NULL,
        gst_number VARCHAR(20) DEFAULT NULL,
        address TEXT NOT NULL,
        city VARCHAR(50) NOT NULL,
        state VARCHAR(50) NOT NULL,
        pincode VARCHAR(6) NOT NULL,
        is_active BOOLEAN DEFAULT TRUE,
        joined_at TIMESTAMP DEFAULT NOW()
      );
    `);

    console.log('✅ Database schema verified / initialized');
  } catch (err) {
    console.error('Schema initialization notice:', err);
  }
};

export const testConnection = async (): Promise<void> => {
  let attempts = 0;
  while (attempts < 5) {
    try {
      const client = await pool.connect();
      console.log('✅ PostgreSQL connected successfully');
      client.release();
      await initDatabase();
      return;
    } catch (error) {
      attempts++;
      console.error(`❌ PostgreSQL connection attempt ${attempts} failed:`, (error as Error).message);
      if (attempts >= 5) {
        console.error('❌ Could not connect after 5 attempts. Exiting.');
        process.exit(1);
      }
      console.log(`⏳ Retrying in 3 seconds...`);
      await new Promise((r) => setTimeout(r, 3000));
    }
  }
};

export default pool;
