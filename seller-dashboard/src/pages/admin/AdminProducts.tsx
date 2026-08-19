import React, { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { EmptyState } from '../../components/common/EmptyState';
import { adminService } from '../../services/adminService';
import { Product } from '../../types';
import { Search, Layers, Package, Store, Barcode } from 'lucide-react';
import toast from 'react-hot-toast';

export const AdminProducts: React.FC = () => {
  const { onOpenSidebar } = useOutletContext<{ onOpenSidebar: () => void }>();

  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    const loadProducts = async () => {
      try {
        const data = await adminService.getAllProducts();
        setProducts(data);
      } catch {
        toast.error('Failed to load products catalog');
      } finally {
        setLoading(false);
      }
    };

    loadProducts();
  }, []);

  const filteredProducts = products.filter((p) => {
    const q = searchQuery.toLowerCase();
    return (
      p.name.toLowerCase().includes(q) ||
      (p.category && p.category.toLowerCase().includes(q)) ||
      (p.wholesaler?.businessName && p.wholesaler.businessName.toLowerCase().includes(q)) ||
      (p.barcode && p.barcode.includes(q))
    );
  });

  return (
    <div className="flex flex-col min-h-screen bg-gray-50 pb-12">
      <Header
        onOpenSidebar={onOpenSidebar}
        title="Global Marketplace Products"
        subtitle="Audit and oversee products listed by all wholesale sellers"
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
              placeholder="Search by product name, category, seller or barcode..."
              className="w-full pl-9 pr-4 py-2 rounded-xl border border-gray-200 text-xs focus:outline-none focus:ring-2 focus:ring-brand-500 font-medium"
            />
          </div>
          <div className="text-xs font-bold text-gray-500">
            Total Live Products: {products.length}
          </div>
        </div>

        {/* Table */}
        {loading ? (
          <LoadingSpinner message="Auditing global product catalog..." />
        ) : filteredProducts.length === 0 ? (
          <EmptyState
            title="No Products Found"
            description="No marketplace products match your search query."
          />
        ) : (
          <div className="bg-white rounded-2xl border border-gray-200 shadow-card overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-gray-50/80 text-gray-500 font-bold uppercase text-[10px] tracking-wider border-b border-gray-100">
                  <tr>
                    <th className="py-3.5 px-4">Product</th>
                    <th className="py-3.5 px-4">Wholesale Seller</th>
                    <th className="py-3.5 px-4">Category</th>
                    <th className="py-3.5 px-4">Price</th>
                    <th className="py-3.5 px-4">Available Stock</th>
                    <th className="py-3.5 px-4">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 font-medium">
                  {filteredProducts.map((p) => (
                    <tr key={p.id} className="hover:bg-gray-50/60 transition-colors">
                      <td className="py-3.5 px-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-xl bg-gray-100 border border-gray-200 flex items-center justify-center overflow-hidden shrink-0">
                            {p.imageUrl ? (
                              <img
                                src={
                                  p.imageUrl.startsWith('http')
                                    ? p.imageUrl
                                    : `http://localhost:3000${p.imageUrl}`
                                }
                                alt={p.name}
                                className="w-full h-full object-cover"
                              />
                            ) : (
                              <Package className="w-4 h-4 text-gray-400" />
                            )}
                          </div>
                          <div className="flex flex-col">
                            <span className="font-extrabold text-gray-900 text-sm">
                              {p.name}
                            </span>
                            {p.barcode && (
                              <span className="text-[10px] text-gray-400 font-mono">
                                SKU: {p.barcode}
                              </span>
                            )}
                          </div>
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <span className="font-bold text-brand-700">
                          {p.wholesaler?.businessName || 'Wholesaler'}
                        </span>
                      </td>

                      <td className="py-3.5 px-4 text-gray-600">
                        {p.category || 'General'}
                      </td>

                      <td className="py-3.5 px-4 font-black text-gray-900">
                        ₹{Number(p.pricePerUnit).toLocaleString()} / {p.unit}
                      </td>

                      <td className="py-3.5 px-4 font-bold text-gray-800">
                        {p.stockQuantity} {p.unit}
                      </td>

                      <td className="py-3.5 px-4">
                        {Number(p.stockQuantity) > 0 ? (
                          <span className="px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 text-[11px] font-bold border border-emerald-200">
                            Available
                          </span>
                        ) : (
                          <span className="px-2 py-0.5 rounded bg-rose-50 text-rose-700 text-[11px] font-bold border border-rose-200">
                            Out of Stock
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
