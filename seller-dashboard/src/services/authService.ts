import api from '../api/client';
import { User } from '../types';

export interface LoginResponse {
  accessToken: string;
  user: User;
}

export interface RegisterDto {
  email: string;
  password: string;
  name: string;
  phone?: string;
  businessName?: string;
  gstNumber?: string;
  panNumber?: string;
  address?: string;
  shopNumber?: string;
}

export const authService = {
  login: async (email: string, password: string): Promise<LoginResponse> => {
    const res = await api.post('/auth/login', { email, password });
    return res.data;
  },

  register: async (dto: RegisterDto): Promise<LoginResponse> => {
    const res = await api.post('/auth/register', {
      ...dto,
      role: 'WHOLESALER',
    });
    return res.data;
  },

  getMe: async (): Promise<User> => {
    const res = await api.get('/users/me');
    return res.data;
  },

  sendOtp: async (phone: string): Promise<{ success: boolean; message: string }> => {
    const res = await api.post('/auth/otp/send', { phone, role: 'WHOLESALER' });
    return res.data;
  },

  verifyOtp: async (phone: string, otp: string, name?: string): Promise<LoginResponse> => {
    const res = await api.post('/auth/otp/verify', { phone, otp, role: 'WHOLESALER', name });
    return res.data;
  },
};
