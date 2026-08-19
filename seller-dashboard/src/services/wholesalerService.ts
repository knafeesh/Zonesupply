import api from '../api/client';
import {
  Wholesaler,
  SellerAnalytics,
  SellerPaymentSummary,
  SettlementRecord,
  SellerLedgerEntryRecord,
  WholesalerPaymentAccount,
} from '../types';

export const wholesalerService = {
  // Get seller profile
  getProfile: async (): Promise<Wholesaler> => {
    const res = await api.get('/wholesalers/profile');
    return res.data;
  },

  // Update seller profile
  updateProfile: async (
    data: Partial<
      Wholesaler & {
        name?: string;
        phone?: string;
        email?: string;
        profilePicture?: string;
        latitude?: number;
        longitude?: number;
      }
    >
  ): Promise<Wholesaler> => {
    const res = await api.patch('/wholesalers/profile', data);
    return res.data;
  },

  // Upload seller profile or store photo
  uploadImage: async (file: File): Promise<{ filename: string; url: string }> => {
    const formData = new FormData();
    formData.append('file', file);
    const res = await api.post('/products/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return res.data;
  },

  // Get seller dashboard analytics
  getAnalytics: async (): Promise<SellerAnalytics> => {
    const res = await api.get('/wholesalers/analytics/overview');
    return res.data;
  },

  // ─── Seller Payment & Settlement Ledger ───────────────────────────────────

  // Get complete payment KPI summary
  getPaymentSummary: async (): Promise<SellerPaymentSummary> => {
    try {
      const res = await api.get('/seller-ledger/my/summary');
      return res.data;
    } catch {
      return {
        totalSales: 0,
        grossAmount: 0,
        platformCommission: 0,
        refunds: 0,
        pendingSettlement: 0,
        availableSettlement: 0,
        totalSettled: 0,
      };
    }
  },

  // Get all ledger entries
  getSellerLedgerEntries: async (): Promise<SellerLedgerEntryRecord[]> => {
    try {
      const res = await api.get('/seller-ledger/my');
      return res.data;
    } catch {
      return [];
    }
  },

  // Get settlement history
  getSettlements: async (): Promise<SettlementRecord[]> => {
    try {
      const res = await api.get('/seller-ledger/my/settlements');
      return res.data;
    } catch {
      return [];
    }
  },

  // Get linked payout bank / VPA account
  getPaymentAccount: async (): Promise<WholesalerPaymentAccount> => {
    try {
      const res = await api.get('/seller-ledger/my/payment-account');
      return res.data;
    } catch {
      return {
        status: 'NOT_CONFIGURED',
        isVerified: false,
      };
    }
  },

  // Update payout bank / VPA account
  updatePaymentAccount: async (data: {
    beneficiaryName?: string;
    accountNumber?: string;
    ifscCode?: string;
    bankName?: string;
    vpaId?: string;
  }): Promise<WholesalerPaymentAccount> => {
    const res = await api.patch('/seller-ledger/my/payment-account', data);
    return res.data;
  },

  // ─── Legacy Credit Ledger ────────────────────────────────────────────────
  getLedger: async (): Promise<any> => {
    try {
      const res = await api.get('/credit-ledger/wholesaler/outstanding');
      return res.data;
    } catch {
      return { outstanding: 0, retailers: [] };
    }
  },

  getTransactions: async (): Promise<any[]> => {
    try {
      const res = await api.get('/credit-ledger/wholesaler/transactions');
      return res.data;
    } catch {
      return [];
    }
  },
};
