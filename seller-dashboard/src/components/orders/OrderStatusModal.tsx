import React, { useState } from 'react';
import { Modal } from '../common/Modal';
import { Order, OrderStatus } from '../../types';
import { orderService } from '../../services/orderService';
import toast from 'react-hot-toast';

interface OrderStatusModalProps {
  isOpen: boolean;
  onClose: () => void;
  order: Order | null;
  onSuccess: () => void;
}

const STATUS_FLOW: { status: OrderStatus; label: string; desc: string; color: string }[] = [
  { status: 'PENDING', label: 'Pending Review', desc: 'Order received from retailer', color: 'text-amber-600' },
  { status: 'CONFIRMED', label: 'Confirmed / Packing', desc: 'Stock reserved & packing goods', color: 'text-blue-600' },
  { status: 'IN_TRANSIT', label: 'In Transit / Dispatched', desc: 'Handed over to delivery partner', color: 'text-purple-600' },
  { status: 'DELIVERED', label: 'Delivered', desc: 'Received & verified by retailer', color: 'text-emerald-600' },
  { status: 'CANCELLED', label: 'Cancelled', desc: 'Order voided & stock returned', color: 'text-rose-600' },
];

export const OrderStatusModal: React.FC<OrderStatusModalProps> = ({
  isOpen,
  onClose,
  order,
  onSuccess,
}) => {
  const [selectedStatus, setSelectedStatus] = useState<OrderStatus>(
    order?.status || 'CONFIRMED'
  );
  const [updating, setUpdating] = useState(false);

  React.useEffect(() => {
    if (order) setSelectedStatus(order.status);
  }, [order, isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!order) return;

    setUpdating(true);
    try {
      await orderService.updateStatus(order.id, selectedStatus);
      toast.success(`Order status updated to ${selectedStatus}!`);
      onSuccess();
      onClose();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to update status');
    } finally {
      setUpdating(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Update Order Status"
      subtitle={`Order #${order?.id.slice(0, 8)} · Retailer: ${order?.retailer?.shopName || 'Retailer'}`}
      maxWidth="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-2">
          {STATUS_FLOW.map((item) => (
            <label
              key={item.status}
              className={`flex items-start gap-3 p-3 rounded-xl border cursor-pointer transition-all ${
                selectedStatus === item.status
                  ? 'border-brand-500 bg-brand-50/50 shadow-sm'
                  : 'border-gray-200 hover:bg-gray-50'
              }`}
            >
              <input
                type="radio"
                name="order_status"
                value={item.status}
                checked={selectedStatus === item.status}
                onChange={() => setSelectedStatus(item.status)}
                className="mt-1 text-brand-600 focus:ring-brand-500"
              />
              <div className="flex flex-col">
                <span className={`text-xs font-bold ${item.color}`}>
                  {item.label}
                </span>
                <span className="text-[11px] text-gray-500">{item.desc}</span>
              </div>
            </label>
          ))}
        </div>

        <div className="flex items-center justify-end gap-2 pt-4 border-t border-gray-100">
          <button
            type="button"
            onClick={onClose}
            className="py-2 px-4 rounded-xl border border-gray-200 text-xs font-bold text-gray-600 hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={updating}
            className="py-2 px-5 rounded-xl bg-brand-600 hover:bg-brand-500 text-white text-xs font-bold shadow-sm disabled:opacity-50"
          >
            {updating ? 'Updating...' : 'Save Status'}
          </button>
        </div>
      </form>
    </Modal>
  );
};
