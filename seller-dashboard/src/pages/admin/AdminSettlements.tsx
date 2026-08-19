import React, { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { EmptyState } from '../../components/common/EmptyState';
import { adminService } from '../../services/adminService';
import {
  Wallet,
  TrendingUp,
  Percent,
  CheckCircle2,
  Clock,
  Send,
  Building2,
  RefreshCw,
  Search,
  AlertCircle,
  X,
  FileCheck,
} from 'lucide-react';
import toast from 'react-hot-toast';

export const AdminSettlements: React.FC = () => {
  const { onOpenSidebar } = useOutletContext<{ onOpenSidebar: () => void }>();

  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [balances, setBalances] = useState<any[]>([]);
  const [searchQuery, setSearchQuery] = useState('');

  // Settlement payout modal
  const [selectedSeller, setSelectedSeller] = useState<any | null>(null);
  const [paymentRef, setPaymentRef] = useState('');
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const fetchData = async () => {
    try {
      const data = await adminService.getAllPendingBalances();
      setBalances(data);
    } catch {
      toast.error('Failed to load seller payout balances');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleRefresh = () => {
    setRefreshing(true);
    fetchData();
  };

  const handleTriggerSettlement = async () => {
    if (!selectedSeller) return;
    setSubmitting(true);
    try {
      const res = await adminService.triggerSettlement(selectedSeller.wholesalerId, {
        paymentReference: paymentRef.trim() || undefined,
        note: note.trim() || undefined,
      });
      toast.success(
        `Settlement of ₹${Number(res.totalNet).toLocaleString()} completed (UTR: ${res.utrReference || res.paymentReference})`,
      );
      setSelectedSeller(null);
      setPaymentRef('');
      setNote('');
      fetchData();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to execute settlement payout');
    } finally {
      setSubmitting(false);
    }
  };

  const filteredBalances = balances.filter((b) => {
    const q = searchQuery.toLowerCase();
    return (
      b.businessName.toLowerCase().includes(q) ||
      b.wholesalerId.toLowerCase().includes(q)
    );
  });

  const totalPlatformAvailable = balances.reduce((sum, b) => sum + (b.availableSettlement || 0), 0);
  const totalPlatformPending = balances.reduce((sum, b) => sum + (b.pendingSettlement || 0), 0);
  const totalPlatformSettled = balances.reduce((sum, b) => sum + (b.totalSettled || 0), 0);

  if (loading) {
    return (
      <div className="flex flex-col min-h-screen bg-slate-50/60">
        <Header onOpenSidebar={onOpenSidebar} title="Settlement & Payout Management" />
        <div className="flex-1 flex items-center justify-center">
          <LoadingSpinner message="Auditing marketplace settlement queues..." />
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col min-h-screen bg-slate-50/60 pb-12">
      <Header
        onOpenSidebar={onOpenSidebar}
        title="Settlement & Payout Management"
        subtitle="Oversight on seller earnings, platform commission deductions & bank transfers"
      />

      <div className="px-4 sm:px-6 lg:px-8 py-6 space-y-6 max-w-7xl w-full mx-auto">
        {/* KPI Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-gradient-to-br from-brand-600 to-blue-700 text-white p-5 rounded-2xl shadow-md">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-blue-100 uppercase tracking-wider">
                Available for Payout
              </span>
              <div className="p-2 bg-white/20 rounded-xl">
                <Send className="w-4 h-4 text-white" />
              </div>
            </div>
            <div className="text-2xl font-black mt-3">
              ₹{totalPlatformAvailable.toLocaleString('en-IN')}
            </div>
            <span className="text-xs text-blue-200 mt-1 block font-medium">
              Delivered orders eligible for transfer
            </span>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                Pending Delivery / In Transit
              </span>
              <div className="p-2 bg-amber-50 text-amber-600 rounded-xl">
                <Clock className="w-4 h-4" />
              </div>
            </div>
            <div className="text-2xl font-black text-amber-600 mt-3">
              ₹{totalPlatformPending.toLocaleString('en-IN')}
            </div>
            <span className="text-xs text-slate-400 mt-1 block font-medium">
              Active orders awaiting delivery confirmation
            </span>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                Total Payouts Settled
              </span>
              <div className="p-2 bg-emerald-50 text-emerald-600 rounded-xl">
                <CheckCircle2 className="w-4 h-4" />
              </div>
            </div>
            <div className="text-2xl font-black text-emerald-600 mt-3">
              ₹{totalPlatformSettled.toLocaleString('en-IN')}
            </div>
            <span className="text-xs text-slate-400 mt-1 block font-medium">
              Transferred to seller bank accounts with UTR
            </span>
          </div>
        </div>

        {/* Filter Bar */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between gap-4">
          <div className="relative flex-1 max-w-md">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              placeholder="Search by wholesale merchant name..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-9 pr-3 py-2 rounded-xl border border-slate-200 text-xs focus:outline-none focus:ring-2 focus:ring-brand-500 font-medium"
            />
          </div>

          <button
            onClick={handleRefresh}
            disabled={refreshing}
            className="inline-flex items-center gap-1.5 px-3 py-2 bg-white hover:bg-slate-50 text-slate-700 rounded-xl border border-slate-200 text-xs font-bold shadow-sm transition-all"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${refreshing ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        </div>

        {/* Balances Table */}
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          {filteredBalances.length === 0 ? (
            <EmptyState
              title="No Seller Balances"
              description="All seller earnings are settled or no orders are recorded."
            />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 text-slate-500 font-bold uppercase text-[10px] tracking-wider border-b border-slate-100">
                  <tr>
                    <th className="py-3.5 px-4">Wholesale Merchant</th>
                    <th className="py-3.5 px-4">Commission %</th>
                    <th className="py-3.5 px-4">Gross Sales</th>
                    <th className="py-3.5 px-4">Platform Commission</th>
                    <th className="py-3.5 px-4">Pending (In Transit)</th>
                    <th className="py-3.5 px-4">Available for Payout</th>
                    <th className="py-3.5 px-4">Total Settled</th>
                    <th className="py-3.5 px-4 text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {filteredBalances.map((seller) => {
                    const hasAvailable = (seller.availableSettlement || 0) > 0;

                    return (
                      <tr key={seller.wholesalerId} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-3.5 px-4">
                          <div className="flex items-center gap-2.5">
                            <div className="w-8 h-8 rounded-lg bg-brand-50 border border-brand-100 flex items-center justify-center text-brand-700 font-black text-xs">
                              {seller.businessName.charAt(0)}
                            </div>
                            <span className="font-extrabold text-slate-900 text-sm">
                              {seller.businessName}
                            </span>
                          </div>
                        </td>

                        <td className="py-3.5 px-4">
                          <span className="px-2 py-0.5 rounded-md bg-purple-50 text-purple-700 font-bold text-xs">
                            {seller.commissionRate}%
                          </span>
                        </td>

                        <td className="py-3.5 px-4 font-semibold text-slate-900">
                          ₹{Number(seller.totalSales).toLocaleString('en-IN')}
                        </td>

                        <td className="py-3.5 px-4 font-semibold text-purple-700">
                          ₹{Number(seller.totalCommission).toLocaleString('en-IN')}
                        </td>

                        <td className="py-3.5 px-4 text-amber-600 font-semibold">
                          ₹{Number(seller.pendingSettlement).toLocaleString('en-IN')}
                        </td>

                        <td className="py-3.5 px-4 font-black text-brand-700 text-sm">
                          ₹{Number(seller.availableSettlement).toLocaleString('en-IN')}
                        </td>

                        <td className="py-3.5 px-4 text-emerald-600 font-semibold">
                          ₹{Number(seller.totalSettled).toLocaleString('en-IN')}
                        </td>

                        <td className="py-3.5 px-4 text-right">
                          <button
                            onClick={() => setSelectedSeller(seller)}
                            disabled={!hasAvailable}
                            className={`py-1.5 px-3 rounded-xl font-bold text-xs shadow-sm transition-all ${
                              hasAvailable
                                ? 'bg-brand-500 hover:bg-brand-600 text-white'
                                : 'bg-slate-100 text-slate-400 cursor-not-allowed'
                            }`}
                          >
                            Trigger Settlement
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Payout Execution Modal */}
      {selectedSeller && (
        <div className="fixed inset-0 z-50 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4 animate-fade-in">
          <div className="bg-white rounded-3xl p-6 max-w-md w-full shadow-2xl border border-slate-100 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div>
                <h3 className="text-base font-extrabold text-slate-900">
                  Execute Settlement Payout
                </h3>
                <p className="text-xs text-slate-500 font-medium">{selectedSeller.businessName}</p>
              </div>
              <button
                onClick={() => setSelectedSeller(null)}
                className="p-1 text-slate-400 hover:text-slate-600 rounded-lg"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="bg-slate-50 p-4 rounded-2xl space-y-2 text-xs">
              <div className="flex justify-between">
                <span className="text-slate-500">Available Net Payout:</span>
                <span className="font-black text-emerald-600 text-sm">
                  ₹{Number(selectedSeller.availableSettlement).toLocaleString('en-IN')}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Platform Commission Retained:</span>
                <span className="font-semibold text-purple-700">
                  ₹{Number(selectedSeller.totalCommission).toLocaleString('en-IN')} ({selectedSeller.commissionRate}%)
                </span>
              </div>
            </div>

            <div className="space-y-3">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Bank UTR / Transaction Reference (Optional)
                </label>
                <input
                  type="text"
                  placeholder="Auto-generated if blank (e.g. UTR20260818123456)"
                  value={paymentRef}
                  onChange={(e) => setPaymentRef(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-xs font-mono font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Admin Note
                </label>
                <input
                  type="text"
                  placeholder="e.g. Weekly settlement batch"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setSelectedSeller(null)}
                className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleTriggerSettlement}
                disabled={submitting}
                className="flex items-center gap-1.5 px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-md transition-all disabled:opacity-50"
              >
                {submitting ? (
                  <>
                    <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    <span>Processing Payout...</span>
                  </>
                ) : (
                  <>
                    <FileCheck className="w-3.5 h-3.5" />
                    <span>Confirm & Pay Out</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
