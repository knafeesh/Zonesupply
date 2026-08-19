import React, { useState, useEffect } from 'react';
import { useOutletContext, Link } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { StatCard } from '../../components/common/StatCard';
import { Badge } from '../../components/common/Badge';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { ProductModal } from '../../components/products/ProductModal';
import { OrderDetailsDrawer } from '../../components/orders/OrderDetailsDrawer';
import { OrderStatusModal } from '../../components/orders/OrderStatusModal';
import { wholesalerService } from '../../services/wholesalerService';
import { SellerAnalytics, Order } from '../../types';
import {
  IndianRupee,
  ShoppingCart,
  Boxes,
  AlertTriangle,
  TrendingUp,
  Plus,
  ArrowRight,
  ShieldCheck,
  Package,
} from 'lucide-react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from 'recharts';
import toast from 'react-hot-toast';

export const Dashboard: React.FC = () => {
  const { onOpenSidebar } = useOutletContext<{ onOpenSidebar: () => void }>();

  const [analytics, setAnalytics] = useState<SellerAnalytics | null>(null);
  const [loading, setLoading] = useState(true);

  // Modals
  const [showProductModal, setShowProductModal] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [statusOrder, setStatusOrder] = useState<Order | null>(null);

  const fetchAnalytics = async () => {
    try {
      const data = await wholesalerService.getAnalytics();
      setAnalytics(data);
    } catch {
      toast.error('Failed to load dashboard metrics');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAnalytics();
  }, []);

  if (loading) {
    return (
      <div className="flex flex-col h-full">
        <Header onOpenSidebar={onOpenSidebar} title="Dashboard" />
        <LoadingSpinner message="Calculating wholesale analytics..." />
      </div>
    );
  }

  const stats = analytics?.stats || {
    totalRevenue: 0,
    todaySales: 0,
    totalOrders: 0,
    pendingOrders: 0,
    activeOrders: 0,
    totalProducts: 0,
    lowStockProducts: 0,
    outOfStockProducts: 0,
  };

  return (
    <div className="flex flex-col min-h-screen bg-slate-50/60 pb-12">
      <Header
        onOpenSidebar={onOpenSidebar}
        title={analytics?.wholesaler?.businessName || 'Seller Dashboard'}
        subtitle="Wholesale sales, live retailer orders & inventory status"
      />

      <div className="px-4 sm:px-6 lg:px-8 py-6 space-y-6 max-w-7xl w-full mx-auto">
        {/* Storefront Header Card */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-5 rounded-2xl bg-white border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)]">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-xl bg-brand-50 border border-brand-200 text-brand-600 flex items-center justify-center font-black text-base shrink-0">
              {analytics?.wholesaler?.businessName?.charAt(0) || 'S'}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-base font-extrabold text-slate-900">
                  {analytics?.wholesaler?.businessName || 'Wholesale Store'}
                </h2>
                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                  <ShieldCheck className="w-3 h-3" />
                  Verified
                </span>
              </div>
              <p className="text-xs text-slate-500 mt-0.5">
                GST: {analytics?.wholesaler?.gstNumber || 'Not provided'} · Zone:{' '}
                {analytics?.wholesaler?.zone?.name || 'Assigned Zone'}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <button
              onClick={() => setShowProductModal(true)}
              className="flex items-center gap-2 py-2 px-4 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-bold text-xs shadow-btn-primary transition-all"
            >
              <Plus className="w-4 h-4" />
              <span>Add Product</span>
            </button>
            <Link
              to="/orders"
              className="flex items-center gap-1.5 py-2 px-3.5 rounded-xl bg-slate-50 hover:bg-slate-100 text-slate-700 font-bold text-xs border border-slate-200 transition-colors"
            >
              <span>Orders</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>
        </div>

        {/* Low Stock Notice */}
        {stats.lowStockProducts > 0 && (
          <div className="flex items-center justify-between p-4 rounded-2xl bg-amber-50/80 border border-amber-200/80 text-amber-900">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-amber-500 text-white flex items-center justify-center shrink-0">
                <AlertTriangle className="w-4 h-4" />
              </div>
              <div>
                <h4 className="text-xs font-bold uppercase tracking-wider">
                  Low Stock Alert
                </h4>
                <p className="text-xs text-amber-800">
                  {stats.lowStockProducts} products have fewer than 10 units remaining.
                </p>
              </div>
            </div>
            <Link
              to="/inventory"
              className="py-1 px-3 rounded-lg bg-amber-600 hover:bg-amber-700 text-white text-xs font-bold transition-colors"
            >
              View Items
            </Link>
          </div>
        )}

        {/* KPI Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            title="Total Revenue"
            value={`₹${stats.totalRevenue.toLocaleString()}`}
            subtitle="Gross sales"
            icon={IndianRupee}
            color="emerald"
            trend={{ value: 'Active', isPositive: true }}
          />

          <StatCard
            title="Today's Sales"
            value={`₹${stats.todaySales.toLocaleString()}`}
            subtitle="Booked today"
            icon={TrendingUp}
            color="brand"
          />

          <StatCard
            title="Active Orders"
            value={stats.activeOrders}
            subtitle={`${stats.pendingOrders} pending`}
            icon={ShoppingCart}
            color="purple"
          />

          <StatCard
            title="Products Listed"
            value={stats.totalProducts}
            subtitle={`${stats.lowStockProducts} low / ${stats.outOfStockProducts} out`}
            icon={Boxes}
            color="amber"
          />
        </div>

        {/* Charts & Breakdown */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* 7-Day Revenue Trend Chart */}
          <div className="lg:col-span-2 p-5 rounded-2xl bg-white border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)]">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                  7-Day Revenue Overview
                </h3>
                <p className="text-xs text-slate-500">
                  Daily wholesale booking values
                </p>
              </div>
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-brand-50 text-brand-700 border border-brand-200">
                Last 7 Days
              </span>
            </div>

            <div className="h-64 w-full">
              {analytics?.dailyChart && analytics.dailyChart.length > 0 ? (
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={analytics.dailyChart}>
                    <defs>
                      <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#258CFB" stopOpacity={0.25} />
                        <stop offset="95%" stopColor="#258CFB" stopOpacity={0.0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
                    <XAxis
                      dataKey="date"
                      tick={{ fontSize: 11, fill: '#64748B' }}
                      axisLine={false}
                      tickLine={false}
                    />
                    <YAxis
                      tick={{ fontSize: 11, fill: '#64748B' }}
                      axisLine={false}
                      tickLine={false}
                      tickFormatter={(val) => `₹${val}`}
                    />
                    <Tooltip
                      formatter={(val: any) => [`₹${Number(val).toLocaleString()}`, 'Revenue']}
                      contentStyle={{
                        backgroundColor: '#0F172A',
                        color: '#FFF',
                        borderRadius: '12px',
                        fontSize: '12px',
                        border: 'none',
                      }}
                    />
                    <Area
                      type="monotone"
                      dataKey="revenue"
                      stroke="#258CFB"
                      strokeWidth={2.5}
                      fillOpacity={1}
                      fill="url(#colorRev)"
                    />
                  </AreaChart>
                </ResponsiveContainer>
              ) : (
                <div className="flex items-center justify-center h-full text-xs text-slate-400">
                  No sales recorded in the past 7 days
                </div>
              )}
            </div>
          </div>

          {/* Pipeline Card */}
          <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)] flex flex-col justify-between">
            <div>
              <h3 className="text-xs font-bold text-slate-800 uppercase tracking-wider mb-1">
                Fulfillment Status
              </h3>
              <p className="text-xs text-slate-500 mb-4">
                Active pipeline distribution
              </p>

              <div className="space-y-3">
                <div className="flex items-center justify-between p-3 rounded-xl bg-amber-50/70 border border-amber-200/80">
                  <span className="text-xs font-bold text-amber-900">Pending Orders</span>
                  <span className="text-xs font-black text-amber-700 bg-amber-100 px-2 py-0.5 rounded-full">
                    {stats.pendingOrders}
                  </span>
                </div>

                <div className="flex items-center justify-between p-3 rounded-xl bg-blue-50/70 border border-brand-200/80">
                  <span className="text-xs font-bold text-brand-900">In-Progress Orders</span>
                  <span className="text-xs font-black text-brand-700 bg-brand-100 px-2 py-0.5 rounded-full">
                    {stats.activeOrders}
                  </span>
                </div>

                <div className="flex items-center justify-between p-3 rounded-xl bg-emerald-50/70 border border-emerald-200/80">
                  <span className="text-xs font-bold text-emerald-900">Total Completed</span>
                  <span className="text-xs font-black text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full">
                    {stats.totalOrders}
                  </span>
                </div>
              </div>
            </div>

            <div className="pt-4 mt-4 border-t border-slate-100">
              <Link
                to="/products"
                className="flex items-center justify-between text-xs font-bold text-brand-600 hover:text-brand-700"
              >
                <span>View Products Catalog</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          </div>
        </div>

        {/* Recent Orders Table */}
        <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)]">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                Recent Retailer Orders
              </h3>
              <p className="text-xs text-slate-500">
                Latest orders received from retail shops
              </p>
            </div>
            <Link
              to="/orders"
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
                  <th className="py-3 px-4">Retailer</th>
                  <th className="py-3 px-4">Items</th>
                  <th className="py-3 px-4">Total Amount</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium">
                {analytics?.recentOrders && analytics.recentOrders.length > 0 ? (
                  analytics.recentOrders.map((order) => (
                    <tr key={order.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3 px-4 font-mono font-bold text-slate-900">
                        #{order.id.slice(0, 8).toUpperCase()}
                      </td>
                      <td className="py-3 px-4 font-bold text-slate-800">
                        {order.retailer?.shopName || 'Retail Store'}
                      </td>
                      <td className="py-3 px-4 text-slate-500">
                        {order.items?.length || 0} items
                      </td>
                      <td className="py-3 px-4 font-bold text-slate-900">
                        ₹{Number(order.totalAmount).toLocaleString()}
                      </td>
                      <td className="py-3 px-4">
                        <Badge status={order.status} />
                      </td>
                      <td className="py-3 px-4 text-right space-x-2">
                        <button
                          onClick={() => setSelectedOrder(order)}
                          className="py-1 px-2.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs transition-colors"
                        >
                          View
                        </button>
                        <button
                          onClick={() => setStatusOrder(order)}
                          className="py-1 px-2.5 rounded-lg bg-brand-50 hover:bg-brand-100 text-brand-700 font-semibold text-xs transition-colors"
                        >
                          Update
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-slate-400">
                      No orders received yet.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Modals */}
      <ProductModal
        isOpen={showProductModal}
        onClose={() => setShowProductModal(false)}
        onSuccess={fetchAnalytics}
      />

      <OrderDetailsDrawer
        isOpen={!!selectedOrder}
        onClose={() => setSelectedOrder(null)}
        order={selectedOrder}
        onUpdateStatusClick={(ord) => setStatusOrder(ord)}
      />

      <OrderStatusModal
        isOpen={!!statusOrder}
        onClose={() => setStatusOrder(null)}
        order={statusOrder}
        onSuccess={fetchAnalytics}
      />
    </div>
  );
};
