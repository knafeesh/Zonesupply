# Zone Store — Membership Website

A production-ready, full-stack retailer membership application portal for Zone Store.

## 🏗️ Project Structure

```
membership_website/
├── frontend/     React + Vite + TypeScript + Tailwind CSS
└── backend/      Node.js + Express + MySQL
```

---

## 🚀 Quick Start (Local Development)

### Prerequisites
- Node.js 18+
- Docker (running PostgreSQL container `zonesupply_postgres` on port 5433)

### 1. Setup Backend

```bash
cd membership_website/backend

# Install dependencies (already installed)
npm install

# Start backend dev server
npm run dev
```

Backend runs at: `http://localhost:5000`

### 2. Setup Frontend

```bash
cd membership_website/frontend

# Install dependencies (already installed)
npm install

# Start frontend dev server
npm run dev
```

Frontend runs at: `http://localhost:5173`

---

## 🔑 Admin Access

Navigate to: `http://localhost:5173/admin`

| Credential | Value |
|-----------|-------|
| Username | `admin` |
| Password | `Zone@123` |

> ⚠️ The admin route is completely hidden from public navigation.

---

## 📋 Application ID Format

- **Application ID:** `ZS-APP-000001`
- **Membership ID:** `ZS100001`

---

## 🌐 API Endpoints

| Method | Endpoint | Description |
|--------|---------|-------------|
| `GET` | `/api/health` | Health check |
| `POST` | `/api/apply` | Submit membership application |
| `GET` | `/api/status?applicationId=ZS-APP-000001` | Check status by App ID |
| `GET` | `/api/status?mobile=9876543210` | Check status by mobile |
| `POST` | `/api/admin/login` | Admin login |
| `GET` | `/api/admin/applications` | List applications (auth required) |
| `GET` | `/api/admin/applications/:id` | View single application (auth required) |
| `POST` | `/api/admin/approve` | Approve application (auth required) |
| `POST` | `/api/admin/reject` | Reject application (auth required) |

---

## ☁️ Vercel Deployment

### Deploy Frontend

```bash
cd frontend
npm run build
# Push to GitHub, connect to Vercel
# Set VITE_API_URL environment variable to your backend URL
```

### Deploy Backend

```bash
cd backend
# Push to GitHub, connect to Vercel
# Set all .env variables in Vercel dashboard
```

### Environment Variables (Vercel)

**Backend:**
- `DB_HOST` — Your MySQL host (Railway/PlanetScale)
- `DB_PORT` — MySQL port
- `DB_USER` — MySQL username
- `DB_PASSWORD` — MySQL password
- `DB_NAME` — `zonesupply_membership`
- `JWT_SECRET` — A strong random secret
- `FRONTEND_URL` — Your deployed frontend URL

**Frontend:**
- `VITE_API_URL` — Your deployed backend URL + `/api`

---

## 🔒 Security Features

- JWT authentication for admin panel
- bcrypt password hashing
- Rate limiting (apply: 3/hr, status: 20/min, admin login: 5/15min)
- File type validation (JPG/PNG/PDF only, 5MB limit)
- Duplicate mobile prevention (DB UNIQUE constraint)
- Helmet.js HTTP security headers
- CORS origin restriction
- Server-side input validation (express-validator)

---

## 🗄️ Database Tables

| Table | Purpose |
|-------|---------|
| `admin` | Admin credentials |
| `applications` | Membership applications |
| `documents` | Uploaded documents |
| `memberships` | Approved memberships |
| `retailers` | Active retailer profiles |

---

## 📱 Flutter WebView Integration

```dart
WebView(
  initialUrl: 'https://your-membership-site.vercel.app',
  javascriptMode: JavascriptMode.unrestricted,
)
```

---

Built with ❤️ for Zone Store
