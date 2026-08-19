import api from '../api/client';
import {
  AdminStats,
  Wholesaler,
  Product,
  Order,
  SettlementRecord,
  SellerLedgerEntryRecord,
  SettlementCycle,
} from '../types';

export const adminService = {
  // Get platform high-level stats
  getStats: async (): Promise<AdminStats> => {
    const res = await api.get('/admin/stats');
    return res.data;
  },

  // Get payment gateway & collections overview
  getPaymentMetrics: async (): Promise<{
    totalCollections: number;
    successfulPayments: number;
    failedPayments: number;
    totalRefunds: number;
    platformCommission: number;
  }> => {
    try {
      const res = await api.get('/payment/admin/metrics');
      return res.data;
    } catch {
      return {
        totalCollections: 0,
        successfulPayments: 0,
        failedPayments: 0,
        totalRefunds: 0,
        platformCommission: 0,
      };
    }
  },

  // Get all registered sellers
  getAllSellers: async (): Promise<Wholesaler[]> => {
    const res = await api.get('/admin/sellers');
    return res.data;
  },

  // Toggle seller active/suspended status
  toggleSellerStatus: async (sellerId: string): Promise<any> => {
    const res = await api.patch(`/admin/sellers/${sellerId}/toggle-status`);
    return res.data;
  },

  // Update seller platform commission rate
  updateSellerCommission: async (
    sellerId: string,
    commissionRate: number,
  ): Promise<Wholesaler> => {
    const res = await api.patch(`/admin/sellers/${sellerId}/commission`, {
      commissionRate,
    });
    return res.data;
  },

  // Update seller settlement cycle
  updateSettlementCycle: async (
    sellerId: string,
    settlementCycle: SettlementCycle,
  ): Promise<Wholesaler> => {
    const res = await api.patch(`/admin/sellers/${sellerId}/settlement-cycle`, {
      settlementCycle,
    });
    return res.data;
  },

  // Get all products across all wholesalers
  getAllProducts: async (): Promise<Product[]> => {
    const res = await api.get('/admin/products');
    return res.data;
  },

  // Get all marketplace orders
  getAllOrders: async (): Promise<Order[]> => {
    const res = await api.get('/admin/orders');
    return res.data;
  },

  // ─── Settlement & Ledger Oversight ─────────────────────────────────────────

  getAllPendingBalances: async (): Promise<any[]> => {
    try {
      const res = await api.get('/seller-ledger/admin/balances');
      return res.data;
    } catch {
      return [];
    }
  },

  getWholesalerEntries: async (
    wholesalerId: string,
  ): Promise<SellerLedgerEntryRecord[]> => {
    try {
      const res = await api.get(`/seller-ledger/admin/entries/${wholesalerId}`);
      return res.data;
    } catch {
      return [];
    }
  },

  getWholesalerSettlements: async (
    wholesalerId: string,
  ): Promise<SettlementRecord[]> => {
    try {
      const res = await api.get(`/seller-ledger/admin/settlements/${wholesalerId}`);
      return res.data;
    } catch {
      return [];
    }
  },

  triggerSettlement: async (
    wholesalerId: string,
    data: { paymentReference?: string; note?: string },
  ): Promise<SettlementRecord> => {
    const res = await api.post(`/seller-ledger/admin/settle/${wholesalerId}`, data);
    return res.data;
  },

  recordAdjustment: async (
    wholesalerId: string,
    data: { amount: number; isCredit: boolean; note: string },
  ): Promise<any> => {
    const res = await api.post(`/seller-ledger/admin/adjustment/${wholesalerId}`, data);
    return res.data;
  },
};
