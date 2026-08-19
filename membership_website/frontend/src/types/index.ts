// ─── Application Types ────────────────────────────────────────
export interface ApplicationFormData {
  // Step 1
  fullName: string;
  mobile: string;
  email: string;
  // Step 2
  shopName: string;
  businessType: string;
  gstNumber: string;
  address: string;
  state: string;
  city: string;
  pincode: string;
  // Step 3
  aadhaar: File | null;
  pan: File | null;
  shopPhoto: File | null;
  gstCert: File | null;
  // Step 4
  termsAccepted: boolean;
}

export interface ApplicationStatus {
  applicationId: string;
  fullName: string;
  shopName: string;
  status: 'pending' | 'approved' | 'rejected';
  rejectionReason: string | null;
  membershipId: string | null;
  submittedAt: string;
  updatedAt: string;
}

export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  errors?: any[];
}

// ─── Admin Types ─────────────────────────────────────────────
export interface AdminApplication {
  application_id: string;
  full_name: string;
  mobile: string;
  email: string;
  shop_name: string;
  business_type: string;
  city: string;
  state: string;
  status: 'pending' | 'approved' | 'rejected';
  created_at: string;
  membership_id: string | null;
  rejection_reason?: string | null;
  gst_number?: string | null;
  address?: string;
  pincode?: string;
  documents?: DocumentRecord[];
}

export interface DocumentRecord {
  doc_type: 'aadhaar' | 'pan' | 'shop_photo' | 'gst_cert';
  file_name: string;
  file_path: string;
}

export interface AdminStats {
  total: number;
  pending: number;
  approved: number;
  rejected: number;
}

export interface AdminUser {
  id: number;
  username: string;
}

// ─── Indian States ────────────────────────────────────────────
export const INDIAN_STATES = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
  'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
  'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli',
  'Daman and Diu', 'Delhi', 'Lakshadweep', 'Puducherry', 'Ladakh', 'Jammu and Kashmir',
];

export const BUSINESS_TYPES = [
  { value: 'grocery', label: 'Grocery & General Store' },
  { value: 'pharmacy', label: 'Pharmacy / Medical Store' },
  { value: 'electronics', label: 'Electronics & Appliances' },
  { value: 'clothing', label: 'Clothing & Garments' },
  { value: 'restaurant', label: 'Restaurant / Cafe' },
  { value: 'hardware', label: 'Hardware & Tools' },
  { value: 'cosmetics', label: 'Cosmetics & Beauty' },
  { value: 'stationery', label: 'Stationery & Books' },
  { value: 'other', label: 'Other' },
];
