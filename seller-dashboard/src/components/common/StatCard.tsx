import React from 'react';
import { LucideIcon } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: LucideIcon;
  trend?: {
    value: string;
    isPositive: boolean;
  };
  color?: 'brand' | 'emerald' | 'amber' | 'rose' | 'purple';
}

const colorMap = {
  brand: {
    iconBg: 'bg-brand-50 text-brand-600 border border-brand-100',
    border: 'border-slate-200/80',
  },
  emerald: {
    iconBg: 'bg-emerald-50 text-emerald-600 border border-emerald-100',
    border: 'border-slate-200/80',
  },
  amber: {
    iconBg: 'bg-amber-50 text-amber-600 border border-amber-100',
    border: 'border-slate-200/80',
  },
  rose: {
    iconBg: 'bg-rose-50 text-rose-600 border border-rose-100',
    border: 'border-slate-200/80',
  },
  purple: {
    iconBg: 'bg-purple-50 text-purple-600 border border-purple-100',
    border: 'border-slate-200/80',
  },
};

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon: Icon,
  trend,
  color = 'brand',
}) => {
  const c = colorMap[color];

  return (
    <div
      className={`p-5 rounded-2xl bg-white border ${c.border} shadow-[0_2px_12px_rgba(0,0,0,0.03)] hover:shadow-card-hover transition-all duration-200`}
    >
      <div className="flex items-center justify-between gap-3">
        <div className="flex flex-col">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-slate-500">
            {title}
          </span>
          <span className="text-2xl sm:text-3xl font-extrabold text-slate-900 mt-1">
            {value}
          </span>
        </div>
        <div className={`w-11 h-11 rounded-xl ${c.iconBg} flex items-center justify-center`}>
          <Icon className="w-5 h-5" />
        </div>
      </div>

      {(subtitle || trend) && (
        <div className="flex items-center gap-2 mt-3 pt-3 border-t border-slate-100 text-xs text-slate-500">
          {trend && (
            <span
              className={`font-semibold ${
                trend.isPositive ? 'text-emerald-600' : 'text-rose-600'
              }`}
            >
              {trend.isPositive ? '↑' : '↓'} {trend.value}
            </span>
          )}
          {subtitle && <span>{subtitle}</span>}
        </div>
      )}
    </div>
  );
};
