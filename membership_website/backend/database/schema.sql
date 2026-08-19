-- ============================================================
-- Zone Store Membership Website — PostgreSQL Schema
-- ============================================================

-- Run against your existing Docker PostgreSQL container:
-- docker exec -it zonesupply_postgres psql -U zonesupply_user -c "CREATE DATABASE zonesupply_membership;"
-- docker exec -i zonesupply_postgres psql -U zonesupply_user -d zonesupply_membership < database/schema.sql

-- ============================================================
-- ENUM Types
-- ============================================================
DO $$ BEGIN
  CREATE TYPE business_type_enum AS ENUM (
    'grocery', 'pharmacy', 'electronics', 'clothing',
    'restaurant', 'hardware', 'cosmetics', 'stationery', 'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE application_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE doc_type_enum AS ENUM ('aadhaar', 'pan', 'shop_photo', 'gst_cert');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE membership_status_enum AS ENUM ('active', 'suspended');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- Table: admin
-- ============================================================
CREATE TABLE IF NOT EXISTS admin (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- Table: applications
-- ============================================================
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

CREATE INDEX IF NOT EXISTS idx_applications_mobile ON applications(mobile);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_app_id ON applications(application_id);

-- ============================================================
-- Table: documents
-- ============================================================
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

CREATE INDEX IF NOT EXISTS idx_documents_app_id ON documents(application_id, doc_type);

-- ============================================================
-- Table: memberships
-- ============================================================
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

CREATE INDEX IF NOT EXISTS idx_memberships_id ON memberships(membership_id);
CREATE INDEX IF NOT EXISTS idx_memberships_mobile ON memberships(mobile);

-- ============================================================
-- Table: retailers
-- ============================================================
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

CREATE INDEX IF NOT EXISTS idx_retailers_mobile ON retailers(mobile);

-- ============================================================
-- Trigger: auto update updated_at on applications
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_applications_updated_at ON applications;
CREATE TRIGGER trg_applications_updated_at
  BEFORE UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- View: application_overview
-- ============================================================
CREATE OR REPLACE VIEW application_overview AS
SELECT
  a.application_id, a.full_name, a.mobile, a.email,
  a.shop_name, a.business_type, a.city, a.state,
  a.status, a.created_at, m.membership_id
FROM applications a
LEFT JOIN memberships m ON a.application_id = m.application_id
ORDER BY a.created_at DESC;
