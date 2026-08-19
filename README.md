# 🏪 ZoneSupply – Full-Stack Marketplace Platform

A unified wholesale logistics platform connecting **Wholesalers**, **Retailers**, and **Delivery agents** through a single NestJS API server and three Flutter applications.

---

## 📦 Project Structure

```
Zonesupply/
├── docker-compose.yml          # PostgreSQL + Redis
├── .env.example                # Backend environment template
├── backend/                    # NestJS API Server
│   └── src/
│       ├── auth/               # JWT Authentication (all roles)
│       ├── users/              # User management
│       ├── products/           # Wholesale inventory
│       ├── orders/             # Order placement & management
│       ├── consolidation/      # Zone-based order batching logic
│       ├── delivery/           # Delivery agent job management
│       ├── payment/            # Stripe payment (stub → production)
│       ├── notifications/      # Firebase push (stub → production)
│       └── maps/               # Google Maps routes (stub → production)
├── wholesaler_app/             # Flutter – Wholesaler (ZoneSupply)
├── retailer_app/               # Flutter – Retailer
└── delivery_app/               # Flutter – Delivery Agent
```

---

## 🚀 Quick Start

### 1. Start Database & Cache (Docker required)

```bash
docker compose up -d
```

### 2. Start Backend API

```bash
cd backend
cp .env.example .env     # Already done
npm run start:dev        # Runs on http://localhost:3000
```

📚 Swagger Docs: http://localhost:3000/api/docs

### 3. Run Flutter Apps

```bash
# Wholesaler
cd wholesaler_app && flutter run

# Retailer
cd retailer_app && flutter run

# Delivery
cd delivery_app && flutter run
```

---

## 🏗️ Architecture

```
┌──────────────────┐  ┌─────────────────┐  ┌─────────────────────┐
│  Wholesaler App  │  │  Retailer App   │  │   Delivery App       │
│  (zonesupply)    │  │                 │  │                       │
└────────┬─────────┘  └────────┬────────┘  └──────────┬───────────┘
         │                     │                        │
         └─────────────────────┼────────────────────────┘
                               │ HTTP / REST API
                    ┌──────────▼──────────┐
                    │  NestJS API Server  │
                    │  localhost:3000     │
                    ├─────────────────────┤
                    │ Auth   │ Orders     │
                    │ Products│Consolidat.│
                    │ Delivery│ Payment   │
                    │ Maps   │ Push Notif.│
                    └────┬────────────────┘
                         │
            ┌────────────┼────────────┐
            │            │            │
     ┌──────▼─────┐ ┌────▼────┐      │
     │ PostgreSQL  │ │  Redis  │      │
     │   :5432     │ │  :6379  │      │
     └─────────────┘ └─────────┘      │
```

---

## 🔌 API Endpoints

| Module | Endpoint | Role |
|--------|----------|------|
| Auth | `POST /api/v1/auth/register` | All |
| Auth | `POST /api/v1/auth/login` | All |
| Users | `GET /api/v1/users/me` | All |
| Products | `GET /api/v1/products` | All |
| Products | `POST /api/v1/products` | WHOLESALER |
| Orders | `POST /api/v1/orders` | RETAILER |
| Orders | `GET /api/v1/orders/my` | RETAILER |
| Consolidation | `GET /api/v1/consolidation` | WHOLESALER |
| Consolidation | `PATCH /api/v1/consolidation/:id/close` | WHOLESALER |
| Delivery | `GET /api/v1/delivery/jobs/available` | DELIVERY |
| Delivery | `PATCH /api/v1/delivery/jobs/:id/claim` | DELIVERY |
| Payment | `POST /api/v1/payment/create-intent` | RETAILER |
| Maps | `GET /api/v1/maps/route` | All |

---

## 📱 App Features

### 🏪 Wholesaler App (ZoneSupply)
- 📊 Analytics dashboard with revenue line chart
- 📦 Product inventory management (add/edit/stock)
- 📋 All retailer orders overview with status tracking
- 🚀 Consolidation batch view with close & dispatch

### 🛒 Retailer App
- 🔍 Browse wholesale catalog with search
- 🛒 Shopping cart with quantity controls
- 💳 Checkout with zone-based delivery and mock payment
- 📦 Order tracking with consolidation batch indicator

### 🚚 Delivery App
- 💼 Available jobs with zone, order count, and value
- ✅ One-tap job claiming
- 🗺️ Step-by-step delivery confirmation flow
- 🎯 Simulated navigation route (Google Maps-ready)

---

## 🔑 Configure Production APIs

1. **PostgreSQL**: Update `DB_*` vars in `backend/.env`
2. **Stripe Payments**: Set `STRIPE_SECRET_KEY` in `.env`
3. **Firebase Push**: Set `FIREBASE_PROJECT_ID` + `FIREBASE_PRIVATE_KEY`
4. **Google Maps**: Set `GOOGLE_MAPS_API_KEY` in `.env` and update Flutter apps

---

## 🎨 Design System

| App | Primary Color | Theme |
|-----|--------------|-------|
| Wholesaler | `#6C63FF` Purple | Dark glassmorphism |
| Retailer | `#00D4AA` Teal | Dark with emerald accents |
| Delivery | `#FF6B9D` Pink | Dark with amber accents |
