import React, { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { EmptyState } from '../../components/common/EmptyState';
import { StockModal } from '../../components/products/StockModal';
import { productService } from '../../services/productService';
import { Product } from '../../types';
import {
  Boxes,
  AlertTriangle,
  CheckCircle2,
  XCircle,
  RefreshCw,
} from 'lucide-react';
import toast from 'react-hot-toast';

export const Inventory: React.FC = () => {
  const { onOpenSidebar } = useOutletContext<{ onOpenSidebar: () => void }>();

  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterType, setFilterType] = useState<'all' | 'low' | 'out' | 'healthy'>('all');
  const [stockProduct, setStockProduct] = useState<Product | null>(null);

  const fetchProducts = async () => {
    try {
      const data = await productService.getMyProducts();
      setProducts(data);
    } catch {
      toast.error('Failed to load inventory');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProducts();
  }, []);

  const lowStock = products.filter(
    (p) => Number(p.stockQuantity) > 0 && Number(p.stockQuantity) <= 10
  );
  const outOfStock = products.filter((p) => Number(p.stockQuantity) <= 0);
  const healthyStock = products.filter((p) => Number(p.stockQuantity) > 10);

  const displayedProducts = products.filter((p) => {
    if (filterType === 'low') return Number(p.stockQuantity) > 0 && Number(p.stockQuantity) <= 10;
    if (filterType === 'out') return Number(p.stockQuantity) <= 0;
    if (filterType === 'healthy') return Number(p.stockQuantity) > 10;
    return true;
  });

  return (
    <div className="flex flex-col min-h-screen bg-slate-50/60 pb-12">
      <Header
        onOpenSidebar={onOpenSidebar}
        title="Inventory & Stock Health"
        subtitle="Monitor warehouse stock quantities, low-stock warnings & restock actions"
      />

      <div className="px-4 sm:px-6 lg:px-8 py-6 space-y-6 max-w-7xl w-full mx-auto">
        {/* Metric Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <button
            onClick={() => setFilterType('out')}
            className={`p-5 rounded-2xl border text-left transition-all ${
              filterType === 'out'
                ? 'bg-rose-50/60 border-rose-300 ring-2 ring-rose-300'
                : 'bg-white border-slate-200 hover:border-rose-200'
            } shadow-[0_2px_12px_rgba(0,0,0,0.03)]`}
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-rose-700">
                Out of Stock
              </span>
              <XCircle className="w-5 h-5 text-rose-500" />
            </div>
            <div className="text-2xl font-extrabold text-slate-900 mt-1">
              {outOfStock.length}
            </div>
            <span className="text-xs text-rose-600 mt-1 block">
              Unavailable for purchase
            </span>
          </button>

          <button
            onClick={() => setFilterType('low')}
            className={`p-5 rounded-2xl border text-left transition-all ${
              filterType === 'low'
                ? 'bg-amber-50/60 border-amber-300 ring-2 ring-amber-300'
                : 'bg-white border-slate-200 hover:border-amber-200'
            } shadow-[0_2px_12px_rgba(0,0,0,0.03)]`}
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-amber-700">
                Low Stock Alert
              </span>
              <AlertTriangle className="w-5 h-5 text-amber-500" />
            </div>
            <div className="text-2xl font-extrabold text-slate-900 mt-1">
              {lowStock.length}
            </div>
            <span className="text-xs text-amber-700 mt-1 block">
              Fewer than 10 units in stock
            </span>
          </button>

          <button
            onClick={() => setFilterType('healthy')}
            className={`p-5 rounded-2xl border text-left transition-all ${
              filterType === 'healthy'
                ? 'bg-emerald-50/60 border-emerald-300 ring-2 ring-emerald-300'
                : 'bg-white border-slate-200 hover:border-emerald-200'
            } shadow-[0_2px_12px_rgba(0,0,0,0.03)]`}
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-emerald-700">
                Healthy Inventory
              </span>
              <CheckCircle2 className="w-5 h-5 text-emerald-500" />
            </div>
            <div className="text-2xl font-extrabold text-slate-900 mt-1">
              {healthyStock.length}
            </div>
            <span className="text-xs text-emerald-600 mt-1 block">
              Adequate stock available
            </span>
          </button>
        </div>

        {/* Filter Bar */}
        <div className="flex items-center justify-between bg-white p-3 rounded-2xl border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)]">
          <div className="flex items-center gap-2">
            <span className="text-xs font-bold text-slate-400 uppercase px-2">Filter:</span>
            {(['all', 'low', 'out', 'healthy'] as const).map((type) => (
              <button
                key={type}
                onClick={() => setFilterType(type)}
                className={`py-1.5 px-3 rounded-xl text-xs font-semibold transition-all ${
                  filterType === type
                    ? 'bg-brand-500 text-white shadow-btn-primary'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                {type === 'all'
                  ? `All (${products.length})`
                  : type === 'low'
                  ? `Low Stock (${lowStock.length})`
                  : type === 'out'
                  ? `Out of Stock (${outOfStock.length})`
                  : `Healthy (${healthyStock.length})`}
              </button>
            ))}
          </div>

          <button
            onClick={fetchProducts}
            className="p-2 text-slate-500 hover:text-brand-600 rounded-lg hover:bg-slate-50"
            title="Refresh Stock"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>

        {/* Inventory Items Table */}
        {loading ? (
          <LoadingSpinner message="Checking warehouse inventory..." />
        ) : displayedProducts.length === 0 ? (
          <EmptyState
            title="No Items Found"
            description="No inventory records match the selected stock status."
          />
        ) : (
          <div className="bg-white rounded-2xl border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)] overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 text-slate-500 font-bold uppercase text-[10px] tracking-wider border-b border-slate-100">
                  <tr>
                    <th className="py-3.5 px-4">Item Name</th>
                    <th className="py-3.5 px-4">Category</th>
                    <th className="py-3.5 px-4">Unit Price</th>
                    <th className="py-3.5 px-4">Available Quantity</th>
                    <th className="py-3.5 px-4">Stock Status</th>
                    <th className="py-3.5 px-4 text-right">Quick Restock</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {displayedProducts.map((p) => {
                    const isLow = Number(p.stockQuantity) > 0 && Number(p.stockQuantity) <= 10;
                    const isOut = Number(p.stockQuantity) <= 0;

                    return (
                      <tr key={p.id} className="hover:bg-slate-50/70 transition-colors">
                        <td className="py-3.5 px-4">
                          <span className="font-bold text-slate-900 text-sm">
                            {p.name}
                          </span>
                        </td>

                        <td className="py-3.5 px-4 text-slate-500">
                          {p.category || 'General'}
                        </td>

                        <td className="py-3.5 px-4 font-bold text-slate-900">
                          ₹{Number(p.pricePerUnit).toLocaleString()} / {p.unit}
                        </td>

                        <td className="py-3.5 px-4">
                          <span className="text-sm font-extrabold text-slate-900">
                            {p.stockQuantity} {p.unit}
                          </span>
                        </td>

                        <td className="py-3.5 px-4">
                          {isOut ? (
                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-rose-50 text-rose-700 text-xs font-semibold border border-rose-200">
                              <XCircle className="w-3.5 h-3.5" />
                              Out of Stock
                            </span>
                          ) : isLow ? (
                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 text-xs font-semibold border border-amber-200">
                              <AlertTriangle className="w-3.5 h-3.5" />
                              Low Stock ({p.stockQuantity})
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 text-xs font-semibold border border-emerald-200">
                              <CheckCircle2 className="w-3.5 h-3.5" />
                              In Stock
                            </span>
                          )}
                        </td>

                        <td className="py-3.5 px-4 text-right">
                          <button
                            onClick={() => setStockProduct(p)}
                            className="py-1.5 px-3 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-semibold text-xs shadow-btn-primary transition-all"
                          >
                            Update Stock
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      <StockModal
        isOpen={!!stockProduct}
        onClose={() => setStockProduct(null)}
        product={stockProduct}
        onSuccess={fetchProducts}
      />
    </div>
  );
};
