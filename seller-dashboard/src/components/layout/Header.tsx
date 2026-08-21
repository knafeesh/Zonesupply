import React from 'react';
import { Menu, ShieldCheck, Check } from 'lucide-react';
import { useAuth } from '../../auth/AuthContext';

interface HeaderProps {
  onOpenSidebar: () => void;
  title: string;
  subtitle?: string;
}

export const Header: React.FC<HeaderProps> = ({ onOpenSidebar, title, subtitle }) => {
  const { user } = useAuth();

  return (
    <header className="sticky top-0 z-30 flex items-center justify-between h-16 px-4 sm:px-6 bg-white border-b border-slate-200 shadow-sm">
      <div className="flex items-center gap-3">
        <button
          onClick={onOpenSidebar}
          className="p-2 -ml-2 text-slate-600 rounded-lg lg:hidden hover:bg-slate-100 focus:outline-none"
        >
          <Menu className="w-5 h-5" />
        </button>
        <div>
          <h1 className="text-base sm:text-lg font-bold text-slate-900 leading-tight">
            {title}
          </h1>
          {subtitle && (
            <p className="text-xs text-slate-500 hidden sm:block">
              {subtitle}
            </p>
          )}
        </div>
      </div>

      <div className="flex items-center gap-3">
        {/* Marketplace Live Indicator */}
        <div className="hidden md:flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-200/80 text-emerald-700 text-xs font-semibold">
          <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
          <span>Marketplace Connected</span>
        </div>

        {/* User Info */}
        <a
          href="/settings"
          className="flex items-center gap-2 pl-3 border-l border-slate-200 hover:opacity-85 transition-opacity"
        >
          {user?.profilePicture ? (
            <img
              src={
                user.profilePicture.startsWith('/')
                  ? `${(import.meta.env.VITE_API_URL || '').replace(/\/api\/v1\/?$/, '')}${user.profilePicture}`
                  : user.profilePicture
              }
              alt={user.name}
              className="w-8 h-8 rounded-full object-cover border border-brand-200"
            />
          ) : (
            <div className="w-8 h-8 rounded-full bg-brand-50 border border-brand-200 text-brand-700 flex items-center justify-center font-bold text-xs">
              {user?.name?.charAt(0) || 'Z'}
            </div>
          )}
          <div className="hidden sm:flex flex-col text-left">
            <span className="text-xs font-bold text-slate-800 leading-none">
              {user?.name}
            </span>
            <span className="text-[10px] text-slate-500 font-medium">
              {user?.role === 'ADMIN' ? 'Administrator' : 'Wholesale Merchant'}
            </span>
          </div>
        </a>
      </div>
    </header>
  );
};
