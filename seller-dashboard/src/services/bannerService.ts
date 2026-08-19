import api from '../api/client';
import { Banner } from '../types';

export interface CreateBannerDto {
  title: string;
  subtitle?: string;
  tag?: string;
  imageUrl: string;
  category?: string;
  subCategory?: string;
  gradientStart?: string;
  gradientEnd?: string;
  isActive?: boolean;
  displayOrder?: number;
}

export interface UpdateBannerDto extends Partial<CreateBannerDto> {}

export const bannerService = {
  // Get seller's own banners
  getMyBanners: async (): Promise<Banner[]> => {
    const res = await api.get('/banners/my');
    return res.data;
  },

  // Get active banners by category
  getAllBanners: async (category?: string): Promise<Banner[]> => {
    const params = category ? { category } : {};
    const res = await api.get('/banners', { params });
    return res.data;
  },

  // Get single banner
  getBanner: async (id: string): Promise<Banner> => {
    const res = await api.get(`/banners/${id}`);
    return res.data;
  },

  // Create banner
  createBanner: async (dto: CreateBannerDto): Promise<Banner> => {
    const res = await api.post('/banners', dto);
    return res.data;
  },

  // Update banner
  updateBanner: async (id: string, dto: UpdateBannerDto): Promise<Banner> => {
    const res = await api.patch(`/banners/${id}`, dto);
    return res.data;
  },

  // Toggle active status
  toggleBanner: async (id: string): Promise<Banner> => {
    const res = await api.patch(`/banners/${id}/toggle`);
    return res.data;
  },

  // Delete banner
  deleteBanner: async (id: string): Promise<void> => {
    await api.delete(`/banners/${id}`);
  },

  // Upload image
  uploadImage: async (file: File): Promise<{ filename: string; url: string }> => {
    const formData = new FormData();
    formData.append('file', file);
    const res = await api.post('/products/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return res.data;
  },
};
