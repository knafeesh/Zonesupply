import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Package,
  Boxes,
  ShoppingCart,
  Receipt,
  Settings,
  ShieldCheck,
  Users,
  Layers,
  LogOut,
  ChevronRight,
  Store,
  Sparkles,
} from 'lucide-react';
import { useAuth } from '../../auth/AuthContext';

export const Sidebar: React.FC<{ isOpen: boolean; onClose: () => void }> = ({
  isOpen,
  onClose,
}) => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const isAdmin = user?.role === 'ADMIN';

  const sellerNav = [
    { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { to: '/products', label: 'Products', icon: Package },
    { to: '/banners', label: 'Offer Banners', icon: Sparkles },
    { to: '/inventory', label: 'Inventory & Stock', icon: Boxes },
    { to: '/orders', label: 'Orders', icon: ShoppingCart },
    { to: '/ledger', label: 'Credit Ledger', icon: Receipt },
    { to: '/settings', label: 'Store Profile & Settings', icon: Settings },
  ];

  const adminNav = [
    { to: '/admin', label: 'Admin Overview', icon: ShieldCheck },
    { to: '/admin/sellers', label: 'Manage Sellers', icon: Users },
    { to: '/admin/settlements', label: 'Settlements & Payouts', icon: Receipt },
    { to: '/admin/products', label: 'All Products', icon: Layers },
    { to: '/admin/orders', label: 'All Orders', icon: ShoppingCart },
  ];

  const currentNav = isAdmin ? adminNav : sellerNav;

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <>
      {/* Mobile Backdrop */}
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-slate-900/40 backdrop-blur-sm lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed top-0 bottom-0 left-0 z-50 flex flex-col w-64 bg-white border-r border-slate-200 transition-transform duration-200 ease-in-out lg:static lg:translate-x-0 ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Brand Header */}
        <div className="flex items-center gap-3 px-6 h-16 border-b border-slate-100 bg-white">
          <div className="flex items-center justify-center w-9 h-9 rounded-xl bg-brand-500 text-white shadow-btn-primary">
            <Store className="w-5 h-5" />
          </div>
          <div className="flex flex-col">
            <span className="font-extrabold text-sm tracking-tight text-slate-900">
              ZONE SUPPLY
            </span>
            <span className="text-[10px] font-semibold tracking-wider text-brand-600 uppercase">
              {isAdmin ? 'Super Admin' : 'Seller Portal'}
            </span>
          </div>
        </div>

        {/* Nav Links */}
        <div className="flex-1 overflow-y-auto px-3.5 py-5 space-y-1 custom-scrollbar">
          <div className="px-3 pb-2 text-[10px] font-bold tracking-wider text-slate-400 uppercase">
            {isAdmin ? 'Administration' : 'Menu'}
          </div>

          {currentNav.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.to === '/dashboard' || item.to === '/admin'}
                onClick={onClose}
                className={({ isActive }) =>
                  `flex items-center justify-between px-3.5 py-2.5 rounded-xl font-medium text-xs transition-all duration-150 ${
                    isActive
                      ? 'bg-brand-50 text-brand-700 font-semibold border border-brand-100'
                      : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                  }`
                }
              >
                <div className="flex items-center gap-3">
                  <Icon className="w-4 h-4" />
                  <span>{item.label}</span>
                </div>
                <ChevronRight className="w-3.5 h-3.5 opacity-40" />
              </NavLink>
            );
          })}
        </div>

        {/* User Card */}
        <div className="p-4 border-t border-slate-100 bg-slate-50/50">
          <NavLink
            to="/settings"
            onClick={onClose}
            className="flex items-center justify-between gap-3 p-2 rounded-xl bg-white border border-slate-200/80 mb-3 shadow-sm hover:border-brand-300 transition-colors"
          >
            <div className="flex items-center gap-2.5 overflow-hidden">
              {user?.profilePicture ? (
                <img
                  src={
                    user.profilePicture.startsWith('/')
                      ? `${(import.meta.env.VITE_API_URL || '').replace(/\/api\/v1\/?$/, '')}${user.profilePicture}`
                      : user.profilePicture
                  }
                  alt={user.name}
                  className="w-8 h-8 rounded-lg object-cover border border-slate-200 shrink-0"
                />
              ) : (
                <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-brand-500 text-white font-bold text-xs shrink-0">
                  {user?.name?.charAt(0) || 'U'}
                </div>
              )}
              <div className="flex flex-col truncate">
                <span className="text-xs font-bold text-slate-800 truncate">
                  {user?.name || 'User'}
                </span>
                <span className="text-[10px] text-slate-500 truncate">
                  {user?.email}
                </span>
              </div>
            </div>
            <span className="px-1.5 py-0.5 text-[9px] font-bold rounded bg-slate-100 text-slate-600 uppercase shrink-0">
              {user?.role}
            </span>
          </NavLink>

          <button
            onClick={handleLogout}
            className="flex items-center justify-center gap-2 w-full py-2 px-3 rounded-xl text-xs font-semibold text-rose-600 bg-rose-50 hover:bg-rose-100/80 border border-rose-100 transition-colors"
          >
            <LogOut className="w-3.5 h-3.5" />
            Sign Out
          </button>
        </div>
      </aside>
    </>
  );
};
