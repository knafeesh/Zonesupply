# 🚀 Complete Deployment Guide: Membership Website (Vercel + Render + Neon)

This guide walks you through deploying the **Zone Store Membership Website** (Frontend on **Vercel**, Backend on **Render**, Database on **Neon**).

---

## 📦 Architecture Overview
- **Frontend:** React + Vite + TailwindCSS on **Vercel** (Free Edge CDN, Auto SSL, Custom Domain)
- **Backend API:** Node.js + Express + TypeScript on **Render** (Free Web Service)
- **Database:** PostgreSQL on **Neon.tech** (Free Serverless Postgres with Connection Pooling)

---

## 🛠️ Step 1: Create Free PostgreSQL Database on Neon (2 minutes)

1. Go to [https://neon.tech](https://neon.tech) and Sign Up / Log in.
2. Click **"Create Project"**:
   - Project Name: `zonesupply-membership`
   - Region: `Asia Pacific (Singapore)` or `US East`
   - Postgres Version: `16` (Default)
3. Copy your **Postgres Connection String** (it looks like):
   ```text
   postgresql://zonesupply_user:password@ep-cool-frost-12345.ap-southeast-1.aws.neon.tech/zonesupply_membership?sslmode=require
   ```
4. Keep this connection string handy for Step 2.

> **Note:** The backend automatically creates all tables (`applications`, `documents`, `memberships`, `retailers`, `admin`) on its first startup!

---

## 🖥️ Step 2: Deploy Backend API on Render.com (3 minutes)

1. Go to [https://render.com](https://render.com) and Log in with GitHub.
2. Click **"New +"** $\rightarrow$ Select **"Web Service"**.
3. Select your **GitHub repository** (`Zonesupply`).
4. Fill in the service configuration:
   - **Name:** `zonesupply-membership-api`
   - **Root Directory:** `membership_website/backend`
   - **Environment:** `Node`
   - **Build Command:** `npm install && npm run build`
   - **Start Command:** `npm run start`
   - **Instance Type:** `Free`
5. Click **"Advanced"** $\rightarrow$ **"Add Environment Variable"**:
   | Variable | Value |
   | :--- | :--- |
   | `NODE_ENV` | `production` |
   | `PORT` | `10000` |
   | `DATABASE_URL` | *(Paste your Neon connection string from Step 1)* |
   | `JWT_SECRET` | *(Any random secret string e.g. `zone_super_secret_jwt_2026`)* |
   | `ADMIN_PASSWORD` | `Zone@123` |
6. Click **"Create Web Service"**.
7. Wait 1-2 minutes until deployment completes. Render will give you a public URL (e.g. `https://zonesupply-membership-api.onrender.com`).
8. Test your backend: Open `https://zonesupply-membership-api.onrender.com/api/health` in your browser. You should see:
   ```json
   { "success": true, "message": "Zone Store Membership API is running" }
   ```

---

## 🌐 Step 3: Deploy Frontend on Vercel (2 minutes)

1. Go to [https://vercel.com](https://vercel.com) and Log in with GitHub.
2. Click **"Add New Project"** $\rightarrow$ **"Import"** your `Zonesupply` repository.
3. Configure the Project Settings:
   - **Project Name:** `zonesupply-membership`
   - **Framework Preset:** `Vite`
   - **Root Directory:** Click **Edit** and choose `membership_website/frontend`.
   - **Build Command:** `npm run build` (Default)
   - **Output Directory:** `dist` (Default)
4. Add Environment Variable:
   | Key | Value |
   | :--- | :--- |
   | `VITE_API_URL` | `https://zonesupply-membership-api.onrender.com/api` *(Your Render URL + `/api`)* |
5. Click **"Deploy"**.
6. In ~45 seconds, Vercel will give you a live production URL (e.g. `https://zonesupply-membership.vercel.app`)!

---

## 🔐 Admin Portal Credentials
- **Admin Login URL:** `https://your-frontend.vercel.app/admin/login`
- **Username:** `admin`
- **Password:** `Zone@123` (or whatever you set in `ADMIN_PASSWORD`)

---

## 🔄 Updating / Redeploying
- Any new `git push` to your repository will **automatically rebuild and redeploy** both frontend and backend without downtime.
