import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { ProtectedRoute } from './auth/ProtectedRoute';
import { DashboardLayout } from './components/layout/DashboardLayout';

// Auth Pages
import { Login } from './pages/auth/Login';
import { Register } from './pages/auth/Register';

// Seller Pages
import { Dashboard as SellerDashboard } from './pages/seller/Dashboard';
import { Products as SellerProducts } from './pages/seller/Products';
import { Banners as SellerBanners } from './pages/seller/Banners';
import { Inventory as SellerInventory } from './pages/seller/Inventory';
import { Orders as SellerOrders } from './pages/seller/Orders';
import { Ledger as SellerLedger } from './pages/seller/Ledger';
import { Settings as SellerSettings } from './pages/seller/Settings';

// Super Admin Pages
import { AdminOverview } from './pages/admin/AdminOverview';
import { AdminSellers } from './pages/admin/AdminSellers';
import { AdminProducts } from './pages/admin/AdminProducts';
import { AdminOrders } from './pages/admin/AdminOrders';
import { AdminSettlements } from './pages/admin/AdminSettlements';

export const App: React.FC = () => {
  return (
    <Routes>
      {/* Public Auth Routes */}
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />

      {/* Seller Protected Routes */}
      <Route element={<ProtectedRoute allowedRoles={['WHOLESALER', 'ADMIN']} />}>
        <Route element={<DashboardLayout />}>
          <Route path="/dashboard" element={<SellerDashboard />} />
          <Route path="/products" element={<SellerProducts />} />
          <Route path="/banners" element={<SellerBanners />} />
          <Route path="/inventory" element={<SellerInventory />} />
          <Route path="/orders" element={<SellerOrders />} />
          <Route path="/ledger" element={<SellerLedger />} />
          <Route path="/settings" element={<SellerSettings />} />
          <Route path="/profile" element={<SellerSettings />} />
        </Route>
      </Route>

      {/* Super Admin Protected Routes */}
      <Route element={<ProtectedRoute allowedRoles={['ADMIN']} />}>
        <Route element={<DashboardLayout />}>
          <Route path="/admin" element={<AdminOverview />} />
          <Route path="/admin/sellers" element={<AdminSellers />} />
          <Route path="/admin/settlements" element={<AdminSettlements />} />
          <Route path="/admin/products" element={<AdminProducts />} />
          <Route path="/admin/orders" element={<AdminOrders />} />
        </Route>
      </Route>

      {/* Default fallback route */}
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
};

export default App;
