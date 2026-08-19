import React, { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { Badge } from '../../components/common/Badge';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { EmptyState } from '../../components/common/EmptyState';
import { OrderDetailsDrawer } from '../../components/orders/OrderDetailsDrawer';
import { OrderStatusModal } from '../../components/orders/OrderStatusModal';
import { adminService } from '../../services/adminService';
import { Order } from '../../types';
import { Search, ShoppingCart, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';

export const AdminOrders: React.FC = () => {
  const { onOpenSidebar } = useOutletContext<{ onOpenSidebar: () => void }>();

  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  // Modals
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [statusOrder, setStatusOrder] = useState<Order | null>(null);

  const fetchOrders = async () => {
    try {
      const data = await adminService.getAllOrders();
      setOrders(data);
    } catch {
      toast.error('Failed to load marketplace orders');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

  const filteredOrders = orders.filter((o) => {
    const q = searchQuery.toLowerCase();
    return (
      o.id.toLowerCase().includes(q) ||
      (o.wholesaler?.businessName && o.wholesaler.businessName.toLowerCase().includes(q)) ||
      (o.retailer?.shopName && o.retailer.shopName.toLowerCase().includes(q)) ||
      (o.deliveryAddress && o.deliveryAddress.toLowerCase().includes(q))
    );
  });

  return (
    <div className="flex flex-col min-h-screen bg-gray-50 pb-12">
      <Header
        onOpenSidebar={onOpenSidebar}
        title="Global Marketplace Orders"
        subtitle="Oversight across all wholesale transactions, fulfillments & delivery routes"
      />

      <div className="px-4 sm:px-6 lg:px-8 py-6 space-y-6 max-w-7xl w-full mx-auto">
        {/* Search */}
        <div className="bg-white p-3.5 rounded-2xl border border-gray-200 shadow-card flex items-center justify-between">
          <div className="relative flex-1 max-w-md">
            <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by Order ID, Wholesale Seller, or Retailer..."
              className="w-full pl-9 pr-4 py-2 rounded-xl border border-gray-200 text-xs focus:outline-none focus:ring-2 focus:ring-brand-500 font-medium"
            />
          </div>

          <button
            onClick={fetchOrders}
            className="p-2 text-gray-500 hover:text-brand-600 rounded-lg hover:bg-gray-50"
            title="Refresh Orders"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>

        {/* Orders Table */}
        {loading ? (
          <LoadingSpinner message="Auditing marketplace orders..." />
        ) : filteredOrders.length === 0 ? (
          <EmptyState
            title="No Orders Found"
            description="No orders currently match your search query."
          />
        ) : (
          <div className="bg-white rounded-2xl border border-gray-200 shadow-card overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-gray-50/80 text-gray-500 font-bold uppercase text-[10px] tracking-wider border-b border-gray-100">
                  <tr>
                    <th className="py-3.5 px-4">Order ID</th>
                    <th className="py-3.5 px-4">Wholesale Seller</th>
                    <th className="py-3.5 px-4">Retailer</th>
                    <th className="py-3.5 px-4">Items</th>
                    <th className="py-3.5 px-4">Total Amount</th>
                    <th className="py-3.5 px-4">Status</th>
                    <th className="py-3.5 px-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 font-medium">
                  {filteredOrders.map((order) => (
                    <tr key={order.id} className="hover:bg-gray-50/60 transition-colors">
                      <td className="py-3.5 px-4">
                        <div className="flex flex-col">
                          <span className="font-mono font-black text-gray-900 text-sm">
                            #{order.id.slice(0, 8).toUpperCase()}
                          </span>
                          <span className="text-[10px] text-gray-400">
                            {new Date(order.createdAt).toLocaleDateString()}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4 font-bold text-brand-700">
                        {order.wholesaler?.businessName || 'Wholesaler'}
                      </td>

                      <td className="py-3.5 px-4 font-bold text-gray-800">
                        {order.retailer?.shopName || 'Retail Store'}
                      </td>

                      <td className="py-3.5 px-4 text-gray-500">
                        {order.items?.length || 0} Products
                      </td>

                      <td className="py-3.5 px-4 font-black text-gray-900 text-sm">
                        ₹{Number(order.totalAmount).toLocaleString()}
                      </td>

                      <td className="py-3.5 px-4">
                        <Badge status={order.status} />
                      </td>

                      <td className="py-3.5 px-4 text-right space-x-2">
                        <button
                          onClick={() => setSelectedOrder(order)}
                          className="py-1.5 px-3 rounded-xl bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold text-xs transition-colors"
                        >
                          Inspect
                        </button>
                        <button
                          onClick={() => setStatusOrder(order)}
                          className="py-1.5 px-3 rounded-xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs shadow-sm transition-all"
                        >
                          Override
                        </button>
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
