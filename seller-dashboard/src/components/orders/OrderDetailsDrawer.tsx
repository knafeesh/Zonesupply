import React from 'react';
import { Modal } from '../common/Modal';
import { Badge } from '../common/Badge';
import { Order } from '../../types';
import { MapPin, Phone, User, Calendar, Receipt, PackageCheck, CheckCircle2, Clock } from 'lucide-react';

interface OrderDetailsDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  order: Order | null;
  onUpdateStatusClick: (order: Order) => void;
}

export const OrderDetailsDrawer: React.FC<OrderDetailsDrawerProps> = ({
  isOpen,
  onClose,
  order,
  onUpdateStatusClick,
}) => {
  if (!order) return null;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`Order #${order.id.slice(0, 8).toUpperCase()}`}
      subtitle={`Placed on ${new Date(order.createdAt).toLocaleString()}`}
      maxWidth="2xl"
    >
      <div className="space-y-6">
        {/* Status Bar */}
        <div className="flex items-center justify-between p-4 rounded-2xl bg-slate-50 border border-slate-200">
          <div className="flex items-center gap-3">
            <span className="text-xs font-semibold text-slate-500 uppercase">Current Status:</span>
            <Badge status={order.status} />
          </div>
          <button
            onClick={() => {
              onClose();
              onUpdateStatusClick(order);
            }}
            className="py-1.5 px-3.5 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-semibold text-xs shadow-btn-primary transition-all"
          >
            Update Status
          </button>
        </div>

        {/* Customer / Retailer Details */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div className="p-4 rounded-2xl border border-slate-200 bg-white space-y-2">
            <div className="flex items-center gap-2 text-xs font-bold text-slate-500 uppercase">
              <User className="w-3.5 h-3.5 text-brand-500" />
              Retailer Details
            </div>
            <div className="text-sm font-bold text-slate-900">
              {order.retailer?.shopName || 'Retail Store'}
            </div>
            <div className="text-xs text-slate-600 flex items-center gap-1.5">
              <Phone className="w-3 h-3 text-slate-400" />
              {order.retailer?.user?.phone || 'Contact not provided'}
            </div>
            <div className="text-xs text-slate-600">
              Buyer: {order.retailer?.user?.name || 'Retailer Buyer'}
            </div>
          </div>

          <div className="p-4 rounded-2xl border border-slate-200 bg-white space-y-2">
            <div className="flex items-center gap-2 text-xs font-bold text-slate-500 uppercase">
              <MapPin className="w-3.5 h-3.5 text-brand-500" />
              Delivery Address
            </div>
            <p className="text-xs text-slate-700 leading-relaxed font-medium">
              {order.deliveryAddress || 'Store Address on file'}
            </p>
            {order.deliveryOtp && (
              <div className="inline-block px-2.5 py-1 rounded-lg bg-amber-50 text-amber-700 border border-amber-200 text-xs font-mono font-bold">
                Delivery OTP: {order.deliveryOtp}
              </div>
            )}
          </div>
        </div>

        {/* Items List */}
        <div>
          <h4 className="text-xs font-bold text-slate-500 uppercase mb-3 flex items-center gap-1.5">
            <PackageCheck className="w-4 h-4 text-brand-500" />
            Purchased Products ({order.items?.length || 0})
          </h4>

          <div className="border border-slate-200 rounded-2xl overflow-hidden divide-y divide-slate-100">
            {order.items?.map((item) => (
              <div key={item.id} className="flex items-center justify-between p-3.5 bg-white text-xs">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-slate-100 border border-slate-200 flex items-center justify-center overflow-hidden shrink-0">
                    {item.product?.imageUrl ? (
                      <img
                        src={
                          item.product.imageUrl.startsWith('http')
                            ? item.product.imageUrl
                            : `http://localhost:3000${item.product.imageUrl}`
                        }
                        alt="item"
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <Receipt className="w-4 h-4 text-slate-400" />
                    )}
                  </div>
                  <div className="flex flex-col">
                    <span className="font-bold text-slate-900">
                      {item.product?.name || 'Product'}
                    </span>
                    <span className="text-slate-500">
                      ₹{item.unitPrice} × {item.quantity} {item.product?.unit || 'units'}
                    </span>
                  </div>
                </div>
                <span className="font-bold text-slate-900 text-sm">
                  ₹{Number(item.subtotal).toLocaleString()}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Total Summary */}
        <div className="p-4 rounded-2xl bg-brand-50/60 border border-brand-200/80 flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-xs font-bold text-slate-500 uppercase">Payment Status</span>
            <span className="text-xs font-semibold text-slate-700 flex items-center gap-1 mt-0.5">
              {order.isPaid ? (
                <>
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                  Paid Online
                </>
              ) : (
                <>
                  <Clock className="w-3.5 h-3.5 text-amber-600" />
                  Cash / Credit on Delivery
                </>
              )}
            </span>
          </div>
          <div className="flex flex-col text-right">
            <span className="text-xs font-bold text-slate-500 uppercase">Total Amount</span>
            <span className="text-xl font-black text-slate-900">
              ₹{Number(order.totalAmount).toLocaleString()}
            </span>
          </div>
        </div>
      </div>
    </Modal>
  );
};
