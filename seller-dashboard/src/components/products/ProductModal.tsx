import React, { useState, useEffect } from 'react';
import { Modal } from '../common/Modal';
import { Product } from '../../types';
import { productService, CreateProductDto } from '../../services/productService';
import { Upload, X, Plus, Image as ImageIcon, Sparkles } from 'lucide-react';
import toast from 'react-hot-toast';

interface ProductModalProps {
  isOpen: boolean;
  onClose: () => void;
  product?: Product | null;
  onSuccess: () => void;
}

import { PRODUCT_CATEGORIES } from '../../constants/categories';

const UNITS = ['kg', 'piece', 'box', 'carton', 'litre', 'packet', 'bag', 'dozen', 'quintal', 'tin', 'jar', 'metre', 'set'];

export const ProductModal: React.FC<ProductModalProps> = ({
  isOpen,
  onClose,
  product,
  onSuccess,
}) => {
  const isEditing = !!product;

  const [formData, setFormData] = useState<CreateProductDto>({
    name: '',
    description: '',
    category: PRODUCT_CATEGORIES[0].name,
    pricePerUnit: 0,
    unit: 'kg',
    stockQuantity: 100,
    discount: 0,
    barcode: '',
    imageUrl: '',
    images: [],
    isAvailable: true,
  });

  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (product) {
      setFormData({
        name: product.name || '',
        description: product.description || '',
        category: product.category || PRODUCT_CATEGORIES[0].name,
        pricePerUnit: Number(product.pricePerUnit) || 0,
        unit: product.unit || 'kg',
        stockQuantity: Number(product.stockQuantity) || 0,
        discount: Number(product.discount) || 0,
        barcode: product.barcode || '',
        imageUrl: product.imageUrl || '',
        images: product.images || (product.imageUrl ? [product.imageUrl] : []),
        isAvailable: product.isAvailable ?? true,
      });
    } else {
      setFormData({
        name: '',
        description: '',
        category: PRODUCT_CATEGORIES[0].name,
        pricePerUnit: 0,
        unit: 'kg',
        stockQuantity: 100,
        discount: 0,
        barcode: '',
        imageUrl: '',
        images: [],
        isAvailable: true,
      });
    }
  }, [product, isOpen]);

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    setUploading(true);
    try {
      const file = files[0];
      const res = await productService.uploadImage(file);
      const newImages = [...(formData.images || []), res.url];
      setFormData((prev) => ({
        ...prev,
        imageUrl: prev.imageUrl || res.url,
        images: newImages,
      }));
      toast.success('Image uploaded successfully!');
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to upload image');
    } finally {
      setUploading(false);
    }
  };

  const removeImage = (index: number) => {
    const newImages = [...(formData.images || [])];
    newImages.splice(index, 1);
    setFormData((prev) => ({
      ...prev,
      imageUrl: newImages[0] || '',
      images: newImages,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name.trim()) {
      toast.error('Product name is required');
      return;
    }
    if (Number(formData.pricePerUnit) <= 0) {
      toast.error('Price per unit must be greater than 0');
      return;
    }

    setSaving(true);
    try {
      if (isEditing && product) {
        await productService.updateProduct(product.id, formData);
        toast.success('Product updated successfully!');
      } else {
        await productService.createProduct(formData);
        toast.success('Product created successfully!');
      }
      onSuccess();
      onClose();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to save product');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? 'Edit Wholesale Product' : 'Add New Wholesale Product'}
      subtitle={
        isEditing
          ? `Modify price, stock & details for ${product?.name}`
          : 'List a new item on the Zone Store marketplace for retailers'
      }
      maxWidth="2xl"
    >
      <form onSubmit={handleSubmit} className="space-y-5">
        {/* Basic Info */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div className="sm:col-span-2">
            <label className="block text-xs font-bold text-gray-700 uppercase mb-1">
              Product Title *
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              placeholder="e.g. Premium Basmati Rice 25kg Bag"
              className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 font-medium"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-gray-700 uppercase mb-1">
              Category *
            </label>
            <select
              value={formData.category}
              onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white font-medium"
            >
              {PRODUCT_CATEGORIES.map((cat) => (
                <optgroup key={cat.name} label={cat.name}>
                  <option value={cat.name}>{cat.name} (General)</option>
                  {cat.subcategories.map((sub) => (
                    <option key={sub} value={`${cat.name} > ${sub}`}>
                      {cat.name} &gt; {sub}
                    </option>
                  ))}
                </optgroup>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-bold text-gray-700 uppercase mb-1">
              Barcode / SKU
            </label>
            <input
              type="text"
              value={formData.barcode || ''}
              onChange={(e) => setFormData({ ...formData, barcode: e.target.value })}
              placeholder="e.g. 8901030384829"
              className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 font-medium"
            />
          </div>
        </div>

        {/* Pricing & Stock */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 p-4 rounded-2xl bg-gray-50/70 border border-gray-200/80">
          <div>
            <label className="block text-[11px] font-bold text-gray-700 uppercase mb-1">
              Price (₹) *
            </label>
            <input
              type="number"
              step="0.01"
              required
              min="0.01"
              value={formData.pricePerUnit}
              onChange={(e) =>
                setFormData({ ...formData, pricePerUnit: parseFloat(e.target.value) || 0 })
              }
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 font-bold bg-white"
            />
          </div>

          <div>
            <label className="block text-[11px] font-bold text-gray-700 uppercase mb-1">
              Unit *
            </label>
            <select
              value={formData.unit}
              onChange={(e) => setFormData({ ...formData, unit: e.target.value })}
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white font-medium"
            >
              {UNITS.map((u) => (
                <option key={u} value={u}>
                  {u}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-[11px] font-bold text-gray-700 uppercase mb-1">
              Stock Quantity *
            </label>
            <input
              type="number"
              required
              min="0"
              value={formData.stockQuantity}
              onChange={(e) =>
                setFormData({ ...formData, stockQuantity: parseInt(e.target.value) || 0 })
              }
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 font-bold bg-white"
            />
          </div>

          <div>
            <label className="block text-[11px] font-bold text-gray-700 uppercase mb-1">
              Discount (%)
            </label>
            <input
              type="number"
              min="0"
              max="100"
              value={formData.discount || 0}
              onChange={(e) =>
                setFormData({ ...formData, discount: parseFloat(e.target.value) || 0 })
              }
              className="w-full px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 font-bold bg-white"
            />
          </div>
        </div>

        {/* Description */}
        <div>
          <label className="block text-xs font-bold text-gray-700 uppercase mb-1">
            Description & Wholesale Terms
          </label>
          <textarea
            rows={3}
            value={formData.description || ''}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            placeholder="Provide pack size details, minimum bulk purchase guidelines, or brand specifications..."
            className="w-full px-3.5 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 font-medium"
          />
        </div>

        {/* Image Upload */}
        <div>
          <label className="block text-xs font-bold text-gray-700 uppercase mb-2">
            Product Images
          </label>

          <div className="grid grid-cols-3 sm:grid-cols-5 gap-3">
            {formData.images?.map((url, idx) => (
              <div
                key={idx}
                className="relative group rounded-xl overflow-hidden border border-gray-200 aspect-square bg-gray-100"
              >
                <img
                  src={url.startsWith('http') ? url : `http://localhost:3000${url}`}
                  alt="preview"
                  className="w-full h-full object-cover"
                />
                <button
                  type="button"
                  onClick={() => removeImage(idx)}
                  className="absolute top-1 right-1 p-1 rounded-full bg-rose-600 text-white opacity-0 group-hover:opacity-100 transition-opacity shadow-sm"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </div>
            ))}

            <label className="flex flex-col items-center justify-center border-2 border-dashed border-gray-300 rounded-xl aspect-square cursor-pointer hover:border-brand-500 hover:bg-brand-50/50 transition-colors">
              {uploading ? (
                <div className="w-5 h-5 border-2 border-brand-500 border-t-transparent rounded-full animate-spin"></div>
              ) : (
                <>
                  <Upload className="w-5 h-5 text-gray-400 mb-1" />
                  <span className="text-[10px] font-bold text-gray-500 uppercase">Upload</span>
                </>
              )}
              <input
                type="file"
                accept="image/*"
                onChange={handleImageUpload}
                disabled={uploading}
                className="hidden"
              />
            </label>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-100">
          <button
            type="button"
            onClick={onClose}
            className="py-2.5 px-4 rounded-xl border border-gray-200 text-xs font-bold text-gray-600 hover:bg-gray-50 transition-colors"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={saving || uploading}
            className="py-2.5 px-6 rounded-xl bg-brand-600 hover:bg-brand-500 text-white text-xs font-bold shadow-sm transition-all disabled:opacity-50 flex items-center gap-2"
          >
            {saving ? (
              <>
                <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                Saving...
              </>
            ) : isEditing ? (
              'Update Product'
            ) : (
              'Publish to Marketplace'
            )}
          </button>
        </div>
      </form>
    </Modal>
  );
};
