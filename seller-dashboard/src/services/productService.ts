import api from '../api/client';
import { Product } from '../types';

export interface CreateProductDto {
  name: string;
  description?: string;
  pricePerUnit: number;
  unit: string;
  stockQuantity: number;
  category?: string;
  discount?: number;
  barcode?: string;
  imageUrl?: string;
  images?: string[];
  specifications?: Record<string, any>;
  isAvailable?: boolean;
}

export interface UpdateProductDto extends Partial<CreateProductDto> {}

export const productService = {
  // Get seller's own products
  getMyProducts: async (): Promise<Product[]> => {
    const res = await api.get('/products/my');
    return res.data;
  },

  // Get all marketplace products (or browse by category)
  getAllProducts: async (): Promise<Product[]> => {
    const res = await api.get('/products');
    return res.data;
  },

  // Get single product
  getProduct: async (id: string): Promise<Product> => {
    const res = await api.get(`/products/${id}`);
    return res.data;
  },

  // Create product
  createProduct: async (dto: CreateProductDto): Promise<Product> => {
    const res = await api.post('/products', dto);
    return res.data;
  },

  // Update full product
  updateProduct: async (id: string, dto: UpdateProductDto): Promise<Product> => {
    const res = await api.patch(`/products/${id}`, dto);
    return res.data;
  },

  // Quick stock update
  updateStock: async (id: string, quantity: number): Promise<Product> => {
    const res = await api.patch(`/products/${id}/stock`, { quantity });
    return res.data;
  },

  // Delete product
  deleteProduct: async (id: string): Promise<void> => {
    await api.delete(`/products/${id}`);
  },

  // Upload product image
  uploadImage: async (file: File): Promise<{ filename: string; url: string }> => {
    const formData = new FormData();
    formData.append('file', file);
    const res = await api.post('/products/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return res.data;
  },
};
