import React, { useState, useEffect } from 'react';
import { Modal } from '../common/Modal';
import { Product } from '../../types';
import { productService } from '../../services/productService';
import toast from 'react-hot-toast';

interface StockModalProps {
  isOpen: boolean;
  onClose: () => void;
  product: Product | null;
  onSuccess: () => void;
}

export const StockModal: React.FC<StockModalProps> = ({
  isOpen,
  onClose,
  product,
  onSuccess,
}) => {
  const [quantity, setQuantity] = useState<number>(0);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (product) {
      setQuantity(Number(product.stockQuantity) || 0);
    }
  }, [product, isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!product) return;

    setSaving(true);
    try {
      await productService.updateStock(product.id, quantity);
      toast.success(`Stock updated to ${quantity} ${product.unit}!`);
      onSuccess();
      onClose();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to update stock');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Quick Stock Adjustment"
      subtitle={product?.name}
      maxWidth="sm"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-xs font-bold text-gray-700 uppercase mb-1">
            Current Available Units ({product?.unit})
          </label>
          <input
            type="number"
            min="0"
            required
            value={quantity}
            onChange={(e) => setQuantity(parseInt(e.target.value) || 0)}
            className="w-full px-4 py-3 rounded-xl border border-gray-200 text-lg font-black text-gray-900 focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>

        {/* Quick Increment Buttons */}
        <div className="grid grid-cols-4 gap-2">
          {[+10, +50, +100, +500].map((val) => (
            <button
              key={val}
              type="button"
              onClick={() => setQuantity((q) => Math.max(0, q + val))}
              className="py-1.5 px-2 rounded-lg bg-gray-100 hover:bg-gray-200 text-xs font-bold text-gray-700 transition-colors"
            >
              {val > 0 ? `+${val}` : val}
            </button>
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
            disabled={saving}
            className="py-2 px-5 rounded-xl bg-brand-600 hover:bg-brand-500 text-white text-xs font-bold shadow-sm disabled:opacity-50"
          >
            {saving ? 'Updating...' : 'Save Stock'}
          </button>
        </div>
      </form>
    </Modal>
  );
};
