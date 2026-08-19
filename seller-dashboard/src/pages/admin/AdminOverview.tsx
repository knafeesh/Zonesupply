import React, { useState, useEffect } from 'react';
import { useOutletContext, Link } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { StatCard } from '../../components/common/StatCard';
import { Badge } from '../../components/common/Badge';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { adminService } from '../../services/adminService';
import { AdminStats } from '../../types';
import {
  ShieldCheck,
  IndianRupee,
  Users,
  Store,
  ShoppingCart,
  Layers,
  ArrowRight,
  TrendingUp,
} from 'lucide-react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from 'recharts';
import toast from 'react-hot-toast';

export const AdminOverview: React.FC = () => {
  const { onOpenSidebar } = useOutletContext<{ onOpenSidebar: () => void }>();

  const [stats, setStats] = useState<AdminStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadStats = async () => {
      try {
        const data = await adminService.getStats();
        setStats(data);
      } catch {
        toast.error('Failed to load admin metrics');
      } finally {
        setLoading(false);
      }
    };

    loadStats();
  }, []);

  if (loading) {
    return (
      <div className="flex flex-col h-full">
        <Header onOpenSidebar={onOpenSidebar} title="Super Admin Dashboard" />
        <LoadingSpinner message="Calculating platform GMV..." />
      </div>
    );
  }

  return (
    <div className="flex flex-col min-h-screen bg-slate-50/60 pb-12">
      <Header
        onOpenSidebar={onOpenSidebar}
        title="Admin Overview"
        subtitle="Platform-wide multi-vendor marketplace governance & GMV oversight"
      />

      <div className="px-4 sm:px-6 lg:px-8 py-6 space-y-6 max-w-7xl w-full mx-auto">
        {/* Banner */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-5 rounded-2xl bg-white border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)]">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-brand-50 border border-brand-100 flex items-center justify-center text-brand-600">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <div>
              <span className="text-[10px] font-bold uppercase tracking-wider text-brand-600">
                Platform Governance
              </span>
              <h2 className="text-base font-extrabold text-slate-900">
                Zone Supply Central Marketplace
              </h2>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <Link
              to="/admin/sellers"
              className="py-2 px-4 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-bold text-xs shadow-btn-primary transition-all"
            >
              Manage Sellers
            </Link>
            <Link
              to="/admin/products"
              className="py-2 px-3.5 rounded-xl bg-slate-50 hover:bg-slate-100 text-slate-700 font-bold text-xs border border-slate-200 transition-colors"
            >
              Audit Products
            </Link>
          </div>
        </div>

        {/* KPI Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            title="Total Platform GMV"
            value={`₹${(stats?.totalGmv || 0).toLocaleString()}`}
            subtitle="Gross marketplace volume"
            icon={IndianRupee}
            color="emerald"
            trend={{ value: 'Live', isPositive: true }}
          />

          <StatCard
            title="Platform Commission"
            value={`₹${(stats?.totalPlatformCommission || Math.round((stats?.totalGmv || 0) * 0.05)).toLocaleString()}`}
            subtitle="Retained platform fees"
            icon={TrendingUp}
            color="brand"
          />

          <StatCard
            title="Total Settled Payouts"
            value={`₹${(stats?.totalSettledAmount || 0).toLocaleString()}`}
            subtitle="Transferred to sellers"
            icon={ShieldCheck}
            color="purple"
          />

          <StatCard
            title="Total Orders"
            value={stats?.totalOrders || 0}
            subtitle={`${stats?.pendingOrders || 0} pending fulfillment`}
            icon={ShoppingCart}
            color="amber"
          />
        </div>

        {/* Charts & Breakdown */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Monthly GMV Chart */}
          <div className="lg:col-span-2 p-5 rounded-2xl bg-white border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)]">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                  Monthly Platform GMV & Order Volume
                </h3>
                <p className="text-xs text-slate-500">
                  Historical marketplace transaction totals
                </p>
              </div>
            </div>

            <div className="h-64 w-full">
              {stats?.monthlyStats && stats.monthlyStats.length > 0 ? (
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={stats.monthlyStats}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
                    <XAxis
                      dataKey="month"
                      tick={{ fontSize: 11, fill: '#64748B' }}
                      axisLine={false}
                      tickLine={false}
                    />
                    <YAxis
                      tick={{ fontSize: 11, fill: '#64748B' }}
                      axisLine={false}
                      tickLine={false}
                      tickFormatter={(v) => `₹${v}`}
                    />
                    <Tooltip
                      formatter={(val: any) => [`₹${Number(val).toLocaleString()}`, 'GMV']}
                      contentStyle={{
                        backgroundColor: '#0F172A',
                        color: '#FFF',
                        borderRadius: '12px',
                        fontSize: '12px',
                        border: 'none',
                      }}
                    />
                    <Bar dataKey="gmv" fill="#258CFB" radius={[6, 6, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              ) : (
                <div className="flex items-center justify-center h-full text-xs text-slate-400">
                  No monthly transactions recorded yet
                </div>
              )}
            </div>
          </div>

          {/* Quick Metrics Breakdown */}
          <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)] flex flex-col justify-between">
            <div>
              <h3 className="text-xs font-bold text-slate-800 uppercase tracking-wider mb-1">
                Catalog Health
              </h3>
              <p className="text-xs text-slate-500 mb-4">
                Global products listed across wholesalers
              </p>

              <div className="space-y-3">
                <div className="p-3.5 rounded-xl bg-brand-50/60 border border-brand-200/80 flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Layers className="w-4 h-4 text-brand-600" />
                    <span className="text-xs font-semibold text-slate-800">Total Live Products</span>
                  </div>
                  <span className="text-sm font-black text-brand-700">
                    {stats?.totalProducts || 0}
                  </span>
                </div>

                <div className="p-3.5 rounded-xl bg-emerald-50/60 border border-emerald-200/80 flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <ShoppingCart className="w-4 h-4 text-emerald-600" />
                    <span className="text-xs font-semibold text-slate-800">Delivered Orders</span>
                  </div>
                  <span className="text-sm font-black text-emerald-700">
                    {stats?.deliveredOrders || 0}
                  </span>
                </div>

                <div className="p-3.5 rounded-xl bg-amber-50/60 border border-amber-200/80 flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <TrendingUp className="w-4 h-4 text-amber-600" />
                    <span className="text-xs font-semibold text-slate-800">Pending Orders</span>
                  </div>
                  <span className="text-sm font-black text-amber-700">
                    {stats?.pendingOrders || 0}
                  </span>
                </div>
              </div>
            </div>

            <div className="pt-4 border-t border-slate-100">
              <Link
                to="/admin/sellers"
                className="flex items-center justify-between text-xs font-bold text-brand-600 hover:text-brand-700"
              >
                <span>View Registered Sellers</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          </div>
        </div>

        {/* Global Recent Orders */}
        <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)]">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                Recent Marketplace Orders
              </h3>
              <p className="text-xs text-slate-500">
                Latest transactions across all wholesalers
              </p>
            </div>
            <Link
              to="/admin/orders"
              className="text-xs font-bold text-brand-600 hover:text-brand-700 flex items-center gap-1"
            >
              <span>View All</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 font-bold uppercase text-[10px] tracking-wider border-y border-slate-100">
                <tr>
                  <th className="py-3 px-4">Order ID</th>
                  <th className="py-3 px-4">Wholesale Seller</th>
                  <th className="py-3 px-4">Retailer</th>
                  <th className="py-3 px-4">Amount</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4">Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium">
                {stats?.recentOrders && stats.recentOrders.length > 0 ? (
                  stats.recentOrders.map((order) => (
                    <tr key={order.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3 px-4 font-mono font-bold text-slate-900">
                        #{order.id.slice(0, 8).toUpperCase()}
                      </td>
                      <td className="py-3 px-4 font-bold text-brand-700">
                        {order.wholesaler?.businessName || 'Wholesaler'}
                      </td>
                      <td className="py-3 px-4 text-slate-800">
                        {order.retailer?.shopName || 'Retailer'}
                      </td>
                      <td className="py-3 px-4 font-bold text-slate-900">
                        ₹{Number(order.totalAmount).toLocaleString()}
                      </td>
                      <td className="py-3 px-4">
                        <Badge status={order.status} />
                      </td>
                      <td className="py-3 px-4 text-slate-500">
                        {new Date(order.createdAt).toLocaleDateString()}
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-slate-400">
                      No platform orders recorded yet.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};
