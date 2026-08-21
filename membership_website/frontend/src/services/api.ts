import axios from 'axios';
import { ApplicationFormData, ApiResponse, ApplicationStatus, AdminApplication, AdminStats } from '../types';

const BASE_URL =
  import.meta.env.VITE_API_URL ||
  (import.meta.env.DEV
    ? '/api'
    : 'https://zonesupply-membership-api.onrender.com/api');

const api = axios.create({
  baseURL: BASE_URL,
  timeout: 45000,
});

// Add auth token to admin requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// ─── Public APIs ──────────────────────────────────────────────

export const submitApplication = async (
  formData: ApplicationFormData
): Promise<ApiResponse<{ applicationId: string; status: string }>> => {
  const data = new FormData();
  data.append('fullName', formData.fullName);
  data.append('mobile', formData.mobile);
  data.append('email', formData.email);
  data.append('shopName', formData.shopName);
  data.append('businessType', formData.businessType);
  data.append('gstNumber', formData.gstNumber || '');
  data.append('address', formData.address);
  data.append('state', formData.state);
  data.append('city', formData.city);
  data.append('pincode', formData.pincode);
  data.append('termsAccepted', String(formData.termsAccepted));
  if (formData.aadhaar) data.append('aadhaar', formData.aadhaar);
  if (formData.pan) data.append('pan', formData.pan);
  if (formData.shopPhoto) data.append('shopPhoto', formData.shopPhoto);
  if (formData.gstCert) data.append('gstCert', formData.gstCert);

  const response = await api.post('/apply', data, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
  return response.data;
};

export const checkApplicationStatus = async (
  applicationId?: string,
  mobile?: string
): Promise<ApiResponse<ApplicationStatus>> => {
  const params: Record<string, string> = {};
  if (applicationId) params.applicationId = applicationId;
  if (mobile) params.mobile = mobile;
  const response = await api.get('/status', { params });
  return response.data;
};

// ─── Admin APIs ───────────────────────────────────────────────

export const adminLogin = async (
  username: string,
  password: string
): Promise<ApiResponse<{ token: string; admin: { id: number; username: string } }>> => {
  const response = await api.post('/admin/login', { username, password });
  return response.data;
};

export const getAdminApplications = async (
  status?: string,
  page = 1
): Promise<ApiResponse<AdminApplication[]> & { stats: AdminStats }> => {
  const params: Record<string, any> = { page, limit: 20 };
  if (status) params.status = status;
  const response = await api.get('/admin/applications', { params });
  return response.data;
};

export const getAdminApplicationById = async (
  id: string
): Promise<ApiResponse<AdminApplication>> => {
  const response = await api.get(`/admin/applications/${id}`);
  return response.data;
};

export const approveApplication = async (
  applicationId: string
): Promise<ApiResponse<{ applicationId: string; membershipId: string }>> => {
  const response = await api.post('/admin/approve', { applicationId });
  return response.data;
};

export const rejectApplication = async (
  applicationId: string,
  reason: string
): Promise<ApiResponse> => {
  const response = await api.post('/admin/reject', { applicationId, reason });
  return response.data;
};

export default api;
