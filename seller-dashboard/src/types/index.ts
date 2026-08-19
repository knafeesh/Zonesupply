export type UserRole = 'WHOLESALER' | 'RETAILER' | 'DELIVERY' | 'ADMIN';

export interface User {
  id: string;
  email: string;
  name: string;
  phone?: string;
  role: UserRole;
  isActive: boolean;
  profilePicture?: string;
  createdAt: string;
  updatedAt: string;
}

export type SettlementCycle = 'T_1' | 'T_2' | 'T_7' | 'MANUAL';

export interface WholesalerPaymentAccount {
  id?: string;
  wholesalerId?: string;
  beneficiaryName?: string;
  maskedAccountNumber?: string;
  ifscCode?: string;
  bankName?: string;
  vpaId?: string;
  status: 'NOT_CONFIGURED' | 'PENDING_VERIFICATION' | 'ACTIVE' | 'REJECTED' | 'SUSPENDED';
  isVerified: boolean;
}

export interface Wholesaler {
  id: string;
  userId: string;
  businessName: string;
  gstNumber?: string;
  panNumber?: string;
  address?: string;
  latitude: number;
  longitude: number;
  shopNumber?: string;
  commissionRate?: number;
  settlementCycle?: SettlementCycle;
  paymentAccount?: WholesalerPaymentAccount;
  zoneId?: string;
  zone?: {
    id: string;
    name: string;
  };
  user?: User;
  productCount?: number;
  orderCount?: number;
  createdAt: string;
  updatedAt: string;
}

export interface Product {
  id: string;
  name: string;
  description?: string;
  pricePerUnit: number;
  unit: string;
  stockQuantity: number;
  imageUrl?: string;
  images?: string[];
  category?: string;
  discount: number;
  barcode?: string;
  wholesalerId: string;
  wholesaler?: Wholesaler;
  specifications?: Record<string, any>;
  isAvailable: boolean;
  createdAt: string;
  updatedAt: string;
}

export type OrderStatus =
  | 'PENDING'
  | 'CONFIRMED'
  | 'CONSOLIDATED'
  | 'DISPATCHED'
  | 'IN_TRANSIT'
  | 'DELIVERED'
  | 'SETTLEMENT_ELIGIBLE'
  | 'CANCELLED';

export interface OrderItem {
  id: string;
  orderId: string;
  productId: string;
  product?: Product;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export interface Order {
  id: string;
  orderNumber?: string;
  parentOrderId?: string;
  retailerId: string;
  retailer?: {
    id: string;
    shopName: string;
    address?: string;
    user?: User;
  };
  wholesalerId?: string;
  wholesaler?: Wholesaler;
  zoneId?: string;
  items: OrderItem[];
  childOrders?: Order[];
  status: OrderStatus;
  totalAmount: number;
  sellerGrossAmount?: number;
  commissionRate?: number;
  commissionAmount?: number;
  sellerNetAmount?: number;
  deliveryAddress?: string;
  paymentMethod?: string;
  paymentStatus?: string;
  isPaid: boolean;
  deliveryOtp?: string;
  createdAt: string;
  updatedAt: string;
}

export interface SellerPaymentSummary {
  totalSales: number;
  grossAmount: number;
  platformCommission: number;
  refunds: number;
  pendingSettlement: number;
  availableSettlement: number;
  totalSettled: number;
}

export interface SettlementRecord {
  id: string;
  wholesalerId: string;
  totalGross: number;
  totalCommission: number;
  totalAdjustments: number;
  totalRefunds: number;
  totalNet: number;
  entryCount: number;
  status: 'PENDING' | 'ELIGIBLE' | 'PROCESSING' | 'PAID' | 'COMPLETED' | 'FAILED' | 'ON_HOLD';
  settledAt?: string;
  utrReference?: string;
  paymentReference?: string;
  note?: string;
  createdAt: string;
}

export interface SellerLedgerEntryRecord {
  id: string;
  wholesalerId: string;
  orderId?: string;
  sellerOrderId?: string;
  grossAmount: number;
  commissionAmount: number;
  credit: number;
  debit: number;
  netAmount: number;
  commissionRate: number;
  type: 'SALE' | 'COMMISSION' | 'REFUND' | 'CANCELLATION' | 'ADJUSTMENT' | 'SETTLEMENT' | 'EARNING';
  status: 'PENDING' | 'ELIGIBLE' | 'SETTLED' | 'CANCELLED';
  settlementId?: string;
  settledAt?: string;
  providerReference?: string;
  description?: string;
  note?: string;
  createdAt: string;
}

export interface SellerAnalytics {
  wholesaler: Wholesaler;
  stats: {
    totalRevenue: number;
    todaySales: number;
    totalOrders: number;
    pendingOrders: number;
    activeOrders: number;
    totalProducts: number;
    lowStockProducts: number;
    outOfStockProducts: number;
  };
  dailyChart: {
    date: string;
    revenue: number;
    orders: number;
  }[];
  recentOrders: Order[];
}

export interface AdminStats {
  totalSellers: number;
  totalRetailers: number;
  totalProducts: number;
  totalOrders: number;
  totalGmv: number;
  totalCollections?: number;
  totalPlatformCommission?: number;
  totalRefundedAmount?: number;
  totalSettledAmount?: number;
  pendingOrders: number;
  deliveredOrders: number;
  monthlyStats: {
    month: string;
    gmv: number;
    orders: number;
  }[];
  recentOrders: Order[];
}

export interface ApiResponse<T = any> {
  success?: boolean;
  message?: string;
  data?: T;
  [key: string]: any;
}

export interface Banner {
  id: string;
  wholesalerId: string;
  wholesaler?: Wholesaler;
  title: string;
  subtitle?: string;
  tag: string;
  imageUrl: string;
  category: string;
  subCategory?: string;
  gradientStart: string;
  gradientEnd: string;
  isActive: boolean;
  displayOrder: number;
  createdAt: string;
  updatedAt: string;
}
