import React, { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { EmptyState } from '../../components/common/EmptyState';
import { ConfirmDialog } from '../../components/common/ConfirmDialog';
import { ProductModal } from '../../components/products/ProductModal';
import { StockModal } from '../../components/products/StockModal';
import { productService } from '../../services/productService';
import { Product } from '../../types';
import { ALL_CATEGORY_NAMES } from '../../constants/categories';
import {
  Plus,
  Search,
  Filter,
  Edit2,
  Trash2,
  Package,
  Barcode,
} from 'lucide-react';
import toast from 'react-hot-toast';

export const Products: React.FC = () => {
  const { onOpenSidebar } = useOutletContext<{ onOpenSidebar: () => void }>();

  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('ALL');

  // Modals
  const [productModalOpen, setProductModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [stockProduct, setStockProduct] = useState<Product | null>(null);
  const [deletingProduct, setDeletingProduct] = useState<Product | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  const fetchProducts = async () => {
    try {
      const data = await productService.getMyProducts();
      setProducts(data);
    } catch {
      toast.error('Failed to load products');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProducts();
  }, []);

  const handleDelete = async () => {
    if (!deletingProduct) return;
    setActionLoading(true);
    try {
      await productService.deleteProduct(deletingProduct.id);
      toast.success('Product deleted successfully');
      setDeletingProduct(null);
      fetchProducts();
    } catch {
      toast.error('Failed to delete product');
    } finally {
      setActionLoading(false);
    }
  };

  const categories = [
    'ALL',
    ...Array.from(new Set([...ALL_CATEGORY_NAMES, ...products.map((p) => p.category).filter(Boolean)])),
  ];

  const filteredProducts = products.filter((p) => {
    const matchesSearch =
      p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (p.barcode && p.barcode.includes(searchQuery)) ||
      (p.category && p.category.toLowerCase().includes(searchQuery.toLowerCase()));

    const matchesCategory =
      selectedCategory === 'ALL' ||
      p.category === selectedCategory ||
      (p.category && p.category.startsWith(selectedCategory));

    return matchesSearch && matchesCategory;
  });

  return (
    <div className="flex flex-col min-h-screen bg-slate-50/60 pb-12">
      <Header
        onOpenSidebar={onOpenSidebar}
        title="Products Catalog"
        subtitle="Manage wholesale prices, stock quantities & catalog availability"
      />

      <div className="px-4 sm:px-6 lg:px-8 py-6 space-y-6 max-w-7xl w-full mx-auto">
        {/* Actions & Filters */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)]">
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 flex-1">
            {/* Search Bar */}
            <div className="relative flex-1 max-w-md">
              <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search products by name, barcode, or category..."
                className="w-full pl-9 pr-4 py-2 rounded-xl border border-slate-200 text-xs focus:outline-none focus:ring-2 focus:ring-brand-500 font-medium"
              />
            </div>

            {/* Category Filter */}
            <div className="flex items-center gap-2">
              <Filter className="w-4 h-4 text-slate-400" />
              <select
                value={selectedCategory}
                onChange={(e) => setSelectedCategory(e.target.value)}
                className="py-2 px-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 bg-white focus:outline-none focus:ring-2 focus:ring-brand-500"
              >
                {categories.map((c) => (
                  <option key={c} value={c as string}>
                    {c === 'ALL' ? 'All Categories' : c}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <button
            onClick={() => {
              setEditingProduct(null);
              setProductModalOpen(true);
            }}
            className="flex items-center justify-center gap-2 py-2 px-4 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-bold text-xs shadow-btn-primary transition-all shrink-0"
          >
            <Plus className="w-4 h-4" />
            <span>Add Product</span>
          </button>
        </div>

        {/* Products Table */}
        {loading ? (
          <LoadingSpinner message="Loading catalog items..." />
        ) : filteredProducts.length === 0 ? (
          <EmptyState
            title="No Products Found"
            description={
              searchQuery || selectedCategory !== 'ALL'
                ? 'No items matched your filter criteria.'
                : 'Your catalog is empty. Add your first wholesale product to start selling.'
            }
            actionText={searchQuery || selectedCategory !== 'ALL' ? 'Clear Filters' : 'Add First Product'}
            onAction={() => {
              if (searchQuery || selectedCategory !== 'ALL') {
                setSearchQuery('');
                setSelectedCategory('ALL');
              } else {
                setEditingProduct(null);
                setProductModalOpen(true);
              }
            }}
          />
        ) : (
          <div className="bg-white rounded-2xl border border-slate-200 shadow-[0_2px_12px_rgba(0,0,0,0.03)] overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 text-slate-500 font-bold uppercase text-[10px] tracking-wider border-b border-slate-100">
                  <tr>
                    <th className="py-3.5 px-4">Product Details</th>
                    <th className="py-3.5 px-4">Category</th>
                    <th className="py-3.5 px-4">Wholesale Price</th>
                    <th className="py-3.5 px-4">Available Stock</th>
                    <th className="py-3.5 px-4">Discount</th>
                    <th className="py-3.5 px-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {filteredProducts.map((p) => {
                    const isLowStock = Number(p.stockQuantity) > 0 && Number(p.stockQuantity) <= 10;
                    const isOutOfStock = Number(p.stockQuantity) <= 0;

                    return (
                      <tr key={p.id} className="hover:bg-slate-50/70 transition-colors">
                        <td className="py-3.5 px-4">
                          <div className="flex items-center gap-3">
                            <div className="w-11 h-11 rounded-xl bg-slate-100 border border-slate-200 flex items-center justify-center overflow-hidden shrink-0">
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
                                <Package className="w-5 h-5 text-slate-400" />
                              )}
                            </div>
                            <div className="flex flex-col">
                              <span className="font-bold text-slate-900 text-sm">
                                {p.name}
                              </span>
                              {p.barcode && (
                                <span className="text-[10px] text-slate-400 flex items-center gap-1 font-mono">
                                  <Barcode className="w-3 h-3" />
                                  {p.barcode}
                                </span>
                              )}
                            </div>
                          </div>
                        </td>

                        <td className="py-3.5 px-4">
                          <span className="px-2.5 py-1 rounded-lg bg-slate-100 text-slate-700 text-[11px] font-semibold">
                            {p.category || 'General'}
                          </span>
                        </td>

                        <td className="py-3.5 px-4">
                          <div className="flex flex-col">
                            <span className="font-extrabold text-slate-900 text-sm">
                              ₹{Number(p.pricePerUnit).toLocaleString()}
                            </span>
                            <span className="text-[10px] text-slate-500">per {p.unit}</span>
                          </div>
                        </td>

                        <td className="py-3.5 px-4">
                          <button
                            onClick={() => setStockProduct(p)}
                            className="flex items-center gap-2 group text-left"
                          >
                            <span
                              className={`px-2.5 py-1 rounded-lg text-xs font-bold border transition-all ${
                                isOutOfStock
                                  ? 'bg-rose-50 text-rose-700 border-rose-200'
                                  : isLowStock
                                  ? 'bg-amber-50 text-amber-700 border-amber-200'
                                  : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                              }`}
                            >
                              {p.stockQuantity} {p.unit}
                            </span>
                            <span className="text-[10px] text-brand-600 group-hover:underline font-semibold">
                              Edit
                            </span>
                          </button>
                        </td>

                        <td className="py-3.5 px-4">
                          {Number(p.discount) > 0 ? (
                            <span className="text-xs font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200/60">
                              {p.discount}% Off
                            </span>
                          ) : (
                            <span className="text-slate-400 text-xs">—</span>
                          )}
                        </td>

                        <td className="py-3.5 px-4 text-right">
                          <div className="flex items-center justify-end gap-1.5">
                            <button
                              onClick={() => {
                                setEditingProduct(p);
                                setProductModalOpen(true);
                              }}
                              className="p-1.5 rounded-lg text-slate-500 hover:text-brand-600 hover:bg-brand-50 transition-colors"
                              title="Edit Details"
                            >
                              <Edit2 className="w-4 h-4" />
                            </button>
                            <button
                              onClick={() => setDeletingProduct(p)}
                              className="p-1.5 rounded-lg text-slate-500 hover:text-rose-600 hover:bg-rose-50 transition-colors"
                              title="Delete Item"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
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

      {/* Modals */}
      <ProductModal
        isOpen={productModalOpen}
        onClose={() => setProductModalOpen(false)}
        product={editingProduct}
        onSuccess={fetchProducts}
      />

      <StockModal
        isOpen={!!stockProduct}
        onClose={() => setStockProduct(null)}
        product={stockProduct}
        onSuccess={fetchProducts}
      />

      <ConfirmDialog
        isOpen={!!deletingProduct}
        onClose={() => setDeletingProduct(null)}
        onConfirm={handleDelete}
        title="Delete Product"
        message={`Are you sure you want to delete "${deletingProduct?.name}"?`}
        confirmText="Delete"
        isDangerous
        isLoading={actionLoading}
      />
    </div>
  );
};
