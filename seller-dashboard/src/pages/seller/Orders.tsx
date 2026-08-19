import React, { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { Badge } from '../../components/common/Badge';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { EmptyState } from '../../components/common/EmptyState';
import { OrderDetailsDrawer } from '../../components/orders/OrderDetailsDrawer';
import { OrderStatusModal } from '../../components/orders/OrderStatusModal';
import { orderService } from '../../services/orderService';
import { Order, OrderStatus } from '../../types';
import {
  Search,
  ShoppingCart,
  Clock,
  PackageCheck,
  Truck,
  CheckCircle2,
  XCircle,
  RefreshCw,
} from 'lucide-react';
import toast from 'react-hot-toast';

export const Orders: React.FC = () => {
  const { onOpenSidebar } = useOutletContext<{ onOpenSidebar: () => void }>();

  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<OrderStatus | 'ALL'>('ALL');
  const [searchQuery, setSearchQuery] = useState('');

  // Modals
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [statusOrder, setStatusOrder] = useState<Order | null>(null);

  const fetchOrders = async () => {
    try {
      const data = await orderService.getMyOrders();
      setOrders(data);
    } catch {
      toast.error('Failed to load orders');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

  const tabs: { key: OrderStatus | 'ALL'; label: string; icon: any; count: number }[] = [
    { key: 'ALL', label: 'All Orders', icon: ShoppingCart, count: orders.length },
    {
      key: 'PENDING',
      label: 'Pending',
      icon: Clock,
      count: orders.filter((o) => o.status === 'PENDING').length,
    },
    {
      key: 'CONFIRMED',
      label: 'Confirmed',
      icon: PackageCheck,
      count: orders.filter((o) => o.status === 'CONFIRMED').length,
    },
    {
      key: 'IN_TRANSIT',
      label: 'In Transit',
      icon: Truck,
      count: orders.filter((o) => o.status === 'IN_TRANSIT').length,
    },
    {
      key: 'DELIVERED',
      label: 'Delivered',
      icon: CheckCircle2,
      count: orders.filter((o) => o.status === 'DELIVERED').length,
    },
    {
      key: 'CANCELLED',
      label: 'Cancelled',
      icon: XCircle,
      count: orders.filter((o) => o.status === 'CANCELLED').length,
    },
  ];

  const filteredOrders = orders.filter((o) => {
    const matchesTab = activeTab === 'ALL' || o.status === activeTab;
    const matchesSearch =
      o.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (o.retailer?.shopName &&
        o.retailer.shopName.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (o.deliveryAddress &&
        o.deliveryAddress.toLowerCase().includes(searchQuery.toLowerCase()));

    return matchesTab && matchesSearch;
  });

  return (
    <div className="flex flex-col min-h-screen bg-slate-50/60 pb-12">
      <Header
        onOpenSidebar={onOpenSidebar}
        title="Orders"
        subtitle="Manage retailer order fulfillment, status transitions & delivery tracking"
      />

      <div className="px-4 sm:px-6 lg:px-8 py-6 space-y-6 max-w-7xl w-full mx-auto">
        {/* Pipeline Tabs */}
        <div className="flex items-center gap-2 overflow-x-auto pb-2 custom-scrollbar">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.key;
            return (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={`flex items-center gap-2 py-2 px-4 rounded-xl text-xs font-semibold whitespace-nowrap transition-all border ${
                  isActive
                    ? 'bg-brand-500 text-white border-brand-500 shadow-btn-primary'
                    : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-50'
                }`}
              >
                <Icon className="w-3.5 h-3.5" />
                <span>{tab.label}</span>
                <span
                  className={`px-1.5 py-0.2 rounded-full text-[10px] font-bold ${
                    isActive
                      ? 'bg-white/20 text-white'
                      : 'bg-slate-100 text-slate-700'
                  }`}
                >
                  {tab.count}
                </span>
              </button>
            );
          })}
        </div>

        {/* Search & Action Bar */}
        <div className="flex items-center justify-between gap-4 bg-white p-3.5 rounded-2xl border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)]">
          <div className="relative flex-1 max-w-md">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by Order ID, Retailer name, or address..."
              className="w-full pl-9 pr-4 py-2 rounded-xl border border-slate-200 text-xs focus:outline-none focus:ring-2 focus:ring-brand-500 font-medium"
            />
          </div>

          <button
            onClick={fetchOrders}
            className="p-2 text-slate-500 hover:text-brand-600 rounded-lg hover:bg-slate-50"
            title="Refresh Orders"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>

        {/* Orders Table */}
        {loading ? (
          <LoadingSpinner message="Fetching order pipeline..." />
        ) : filteredOrders.length === 0 ? (
          <EmptyState
            title="No Orders Found"
            description="No orders match the selected status filter."
          />
        ) : (
          <div className="bg-white rounded-2xl border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)] overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 text-slate-500 font-bold uppercase text-[10px] tracking-wider border-b border-slate-100">
                  <tr>
                    <th className="py-3.5 px-4">Order ID & Date</th>
                    <th className="py-3.5 px-4">Retailer / Store</th>
                    <th className="py-3.5 px-4">Products</th>
                    <th className="py-3.5 px-4">Total Amount</th>
                    <th className="py-3.5 px-4">Status</th>
                    <th className="py-3.5 px-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {filteredOrders.map((order) => (
                    <tr key={order.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3.5 px-4">
                        <div className="flex flex-col">
                          <span className="font-mono font-bold text-slate-900 text-sm">
                            #{order.id.slice(0, 8).toUpperCase()}
                          </span>
                          <span className="text-[10px] text-slate-400">
                            {new Date(order.createdAt).toLocaleDateString('en-US', {
                              month: 'short',
                              day: 'numeric',
                              hour: '2-digit',
                              minute: '2-digit',
                            })}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="flex flex-col">
                          <span className="font-bold text-slate-900">
                            {order.retailer?.shopName || 'Retail Store'}
                          </span>
                          <span className="text-[10px] text-slate-500">
                            {order.retailer?.user?.phone || 'No phone'}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="flex flex-col">
                          <span className="text-slate-900 font-semibold">
                            {order.items?.length || 0} items
                          </span>
                          <span className="text-[10px] text-slate-500 truncate max-w-xs">
                            {order.items?.map((i) => i.product?.name).filter(Boolean).join(', ')}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="flex flex-col">
                          <span className="font-bold text-slate-900 text-sm">
                            ₹{Number(order.totalAmount).toLocaleString()}
                          </span>
                          <span className="text-[10px] font-semibold text-emerald-700">
                            {order.isPaid ? 'Paid Online' : 'COD / Credit'}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <Badge status={order.status} />
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => setSelectedOrder(order)}
                            className="py-1.5 px-3 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs transition-colors"
                          >
                            Details
                          </button>
                          <button
                            onClick={() => setStatusOrder(order)}
                            className="py-1.5 px-3 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-semibold text-xs shadow-btn-primary transition-all"
                          >
                            Update Status
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

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
        onSuccess={fetchOrders}
      />
    </div>
  );
};
