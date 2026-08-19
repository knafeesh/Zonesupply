import React, { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { EmptyState } from '../../components/common/EmptyState';
import { wholesalerService } from '../../services/wholesalerService';
import {
  SellerPaymentSummary,
  SettlementRecord,
  SellerLedgerEntryRecord,
  WholesalerPaymentAccount,
} from '../../types';
import {
  Wallet,
  TrendingUp,
  Percent,
  Clock,
  CheckCircle2,
  AlertCircle,
  RotateCcw,
  Building2,
  RefreshCw,
  Search,
  ArrowUpRight,
  ArrowDownLeft,
  FileSpreadsheet,
} from 'lucide-react';
import toast from 'react-hot-toast';

export const Ledger: React.FC = () => {
  const { onOpenSidebar } = useOutletContext<{ onOpenSidebar: () => void }>();

  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [summary, setSummary] = useState<SellerPaymentSummary>({
    totalSales: 0,
    grossAmount: 0,
    platformCommission: 0,
    refunds: 0,
    pendingSettlement: 0,
    availableSettlement: 0,
    totalSettled: 0,
  });
  const [settlements, setSettlements] = useState<SettlementRecord[]>([]);
  const [entries, setEntries] = useState<SellerLedgerEntryRecord[]>([]);
  const [account, setAccount] = useState<WholesalerPaymentAccount | null>(null);

  const [activeTab, setActiveTab] = useState<'settlements' | 'ledger'>('settlements');
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');

  const fetchData = async () => {
    try {
      const [sumData, settsData, entriesData, accData] = await Promise.all([
        wholesalerService.getPaymentSummary(),
        wholesalerService.getSettlements(),
        wholesalerService.getSellerLedgerEntries(),
        wholesalerService.getPaymentAccount(),
      ]);

      setSummary(sumData);
      setSettlements(settsData);
      setEntries(entriesData);
      setAccount(accData);
    } catch {
      toast.error('Failed to load financial records');
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

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'PAID':
      case 'COMPLETED':
      case 'SETTLED':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
            <CheckCircle2 className="w-3.5 h-3.5" />
            Paid / Settled
          </span>
        );
      case 'ELIGIBLE':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold bg-blue-50 text-blue-700 border border-blue-200">
            <TrendingUp className="w-3.5 h-3.5" />
            Available for Payout
          </span>
        );
      case 'PROCESSING':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold bg-indigo-50 text-indigo-700 border border-indigo-200">
            <RefreshCw className="w-3.5 h-3.5 animate-spin" />
            Processing
          </span>
        );
      case 'FAILED':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold bg-rose-50 text-rose-700 border border-rose-200">
            <AlertCircle className="w-3.5 h-3.5" />
            Failed
          </span>
        );
      case 'ON_HOLD':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold bg-purple-50 text-purple-700 border border-purple-200">
            <AlertCircle className="w-3.5 h-3.5" />
            On Hold
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
            <Clock className="w-3.5 h-3.5" />
            Pending Delivery
          </span>
        );
    }
  };

  const filteredSettlements = settlements.filter((s) => {
    const matchesSearch =
      s.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (s.utrReference && s.utrReference.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (s.paymentReference && s.paymentReference.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesStatus = statusFilter === 'ALL' || s.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const filteredEntries = entries.filter((e) => {
    const matchesSearch =
      (e.orderId && e.orderId.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (e.sellerOrderId && e.sellerOrderId.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (e.description && e.description.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesStatus = statusFilter === 'ALL' || e.status === statusFilter || e.type === statusFilter;
    return matchesSearch && matchesStatus;
  });

  if (loading) {
    return (
      <div className="flex flex-col min-h-screen bg-slate-50/60">
        <Header onOpenSidebar={onOpenSidebar} title="Payment & Settlement" />
        <div className="flex-1 flex items-center justify-center">
          <LoadingSpinner message="Auditing financial ledger & settlements..." />
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col min-h-screen bg-slate-50/60 pb-12">
      <Header
        onOpenSidebar={onOpenSidebar}
        title="Payment & Settlement"
        subtitle="Audited financial ledger, earnings breakdown & automated bank payout history"
      />

      <div className="px-4 sm:px-6 lg:px-8 py-6 space-y-6 max-w-7xl w-full mx-auto">
        {/* Top Action Bar */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-black text-slate-900 tracking-tight">
              Payment Summary
            </h2>
            <p className="text-xs text-slate-500 font-medium">
              Verified automated marketplace routing & double-entry financial ledger
            </p>
          </div>

          <div className="flex items-center gap-3">
            {account && (
              <div className="hidden md:flex items-center gap-2 px-3 py-1.5 bg-white rounded-xl border border-slate-200 shadow-sm text-xs font-semibold text-slate-700">
                <Building2 className="w-3.5 h-3.5 text-brand-600" />
                <span>
                  Payout: {account.maskedAccountNumber || 'Account Linked'}{' '}
                  {account.isVerified && <span className="text-emerald-600">✓</span>}
                </span>
              </div>
            )}

            <button
              onClick={handleRefresh}
              disabled={refreshing}
              className="inline-flex items-center gap-1.5 px-3 py-2 bg-white hover:bg-slate-50 text-slate-700 rounded-xl border border-slate-200 text-xs font-bold shadow-sm transition-all"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${refreshing ? 'animate-spin' : ''}`} />
              Refresh
            </button>
          </div>
        </div>

        {/* ─── 7 Key Payment Summary Cards ────────────────────────────────────── */}
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3">
          {/* 1. Total Sales */}
          <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                Total Sales
              </span>
              <div className="p-1.5 bg-blue-50 text-blue-600 rounded-lg">
                <TrendingUp className="w-3.5 h-3.5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-lg font-black text-slate-900">
                ₹{summary.totalSales.toLocaleString('en-IN')}
              </div>
              <span className="text-[10px] text-slate-400 font-medium">Order Value</span>
            </div>
          </div>

          {/* 2. Gross Amount */}
          <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                Gross Amount
              </span>
              <div className="p-1.5 bg-indigo-50 text-indigo-600 rounded-lg">
                <Wallet className="w-3.5 h-3.5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-lg font-black text-indigo-700">
                ₹{summary.grossAmount.toLocaleString('en-IN')}
              </div>
              <span className="text-[10px] text-slate-400 font-medium">Delivered Gross</span>
            </div>
          </div>

          {/* 3. Platform Commission */}
          <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                Commission
              </span>
              <div className="p-1.5 bg-purple-50 text-purple-600 rounded-lg">
                <Percent className="w-3.5 h-3.5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-lg font-black text-purple-700">
                ₹{summary.platformCommission.toLocaleString('en-IN')}
              </div>
              <span className="text-[10px] text-slate-400 font-medium">Platform Fee</span>
            </div>
          </div>

          {/* 4. Refunds */}
          <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                Refunds
              </span>
              <div className="p-1.5 bg-rose-50 text-rose-600 rounded-lg">
                <RotateCcw className="w-3.5 h-3.5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-lg font-black text-rose-600">
                ₹{summary.refunds.toLocaleString('en-IN')}
              </div>
              <span className="text-[10px] text-slate-400 font-medium">Returns / Debits</span>
            </div>
          </div>

          {/* 5. Pending Settlement */}
          <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                In Transit
              </span>
              <div className="p-1.5 bg-amber-50 text-amber-600 rounded-lg">
                <Clock className="w-3.5 h-3.5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-lg font-black text-amber-600">
                ₹{summary.pendingSettlement.toLocaleString('en-IN')}
              </div>
              <span className="text-[10px] text-slate-400 font-medium">Pending Delivery</span>
            </div>
          </div>

          {/* 6. Available Settlement */}
          <div className="bg-gradient-to-br from-brand-600 to-blue-700 text-white p-4 rounded-2xl shadow-md flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-blue-100 uppercase tracking-wider">
                Available
              </span>
              <div className="p-1.5 bg-white/20 rounded-lg">
                <ArrowUpRight className="w-3.5 h-3.5 text-white" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-lg font-black text-white">
                ₹{summary.availableSettlement.toLocaleString('en-IN')}
              </div>
              <span className="text-[10px] text-blue-200 font-medium">Next Payout Batch</span>
            </div>
          </div>

          {/* 7. Total Settled */}
          <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                Total Settled
              </span>
              <div className="p-1.5 bg-emerald-50 text-emerald-600 rounded-lg">
                <CheckCircle2 className="w-3.5 h-3.5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-lg font-black text-emerald-600">
                ₹{summary.totalSettled.toLocaleString('en-IN')}
              </div>
              <span className="text-[10px] text-slate-400 font-medium">Paid to Bank</span>
            </div>
          </div>
        </div>

        {/* ─── Tabs & Filters ─────────────────────────────────────────────────── */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl">
            <button
              onClick={() => setActiveTab('settlements')}
              className={`px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'settlements'
                  ? 'bg-white text-brand-600 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Settlement Payouts ({settlements.length})
            </button>
            <button
              onClick={() => setActiveTab('ledger')}
              className={`px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'ledger'
                  ? 'bg-white text-brand-600 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Transaction Ledger ({entries.length})
            </button>
          </div>

          <div className="flex items-center gap-3">
            <div className="relative flex-1 sm:w-64">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              <input
                type="text"
                placeholder={activeTab === 'settlements' ? 'Search UTR / ID...' : 'Search Order / Details...'}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-9 pr-3 py-1.5 rounded-xl border border-slate-200 text-xs focus:outline-none focus:ring-2 focus:ring-brand-500 font-medium"
              />
            </div>

            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="py-1.5 px-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 bg-white focus:outline-none focus:ring-2 focus:ring-brand-500"
            >
              <option value="ALL">All Statuses</option>
              {activeTab === 'settlements' ? (
                <>
                  <option value="PAID">Paid / Completed</option>
                  <option value="PROCESSING">Processing</option>
                  <option value="ELIGIBLE">Eligible</option>
                  <option value="PENDING">Pending</option>
                </>
              ) : (
                <>
                  <option value="SALE">Sales (Earnings)</option>
                  <option value="REFUND">Refunds</option>
                  <option value="ADJUSTMENT">Adjustments</option>
                  <option value="SETTLED">Settled</option>
                  <option value="PENDING">Pending</option>
                </>
              )}
            </select>
          </div>
        </div>

        {/* ─── Tab Content 1: Settlements History Table ────────────────────────── */}
        {activeTab === 'settlements' && (
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            {filteredSettlements.length === 0 ? (
              <EmptyState
                title="No Settlement Payouts Found"
                description="Completed batch payouts with official UTR numbers will appear here once transferred to your linked bank account."
              />
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 text-slate-500 font-bold uppercase text-[10px] tracking-wider border-b border-slate-100">
                    <tr>
                      <th className="py-3.5 px-4">Settlement ID</th>
                      <th className="py-3.5 px-4">Orders Included</th>
                      <th className="py-3.5 px-4">Gross Amount</th>
                      <th className="py-3.5 px-4">Commission</th>
                      <th className="py-3.5 px-4">Adjustments / Refunds</th>
                      <th className="py-3.5 px-4">Net Payout</th>
                      <th className="py-3.5 px-4">Settlement Date</th>
                      <th className="py-3.5 px-4">Status</th>
                      <th className="py-3.5 px-4">UTR / Transaction Ref</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium">
                    {filteredSettlements.map((st) => (
                      <tr key={st.id} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-3.5 px-4 font-mono font-bold text-slate-800">
                          #{st.id.slice(0, 8).toUpperCase()}
                        </td>

                        <td className="py-3.5 px-4 text-slate-600 font-semibold">
                          {st.entryCount} Orders
                        </td>

                        <td className="py-3.5 px-4 font-semibold text-slate-900">
                          ₹{Number(st.totalGross).toLocaleString('en-IN')}
                        </td>

                        <td className="py-3.5 px-4 font-semibold text-purple-700">
                          -₹{Number(st.totalCommission).toLocaleString('en-IN')}
                        </td>

                        <td className="py-3.5 px-4 text-slate-600">
                          {Number(st.totalRefunds || 0) > 0 ? (
                            <span className="text-rose-600 font-semibold">
                              -₹{Number(st.totalRefunds).toLocaleString('en-IN')}
                            </span>
                          ) : (
                            '₹0'
                          )}
                        </td>

                        <td className="py-3.5 px-4 font-black text-emerald-600 text-sm">
                          ₹{Number(st.totalNet).toLocaleString('en-IN')}
                        </td>

                        <td className="py-3.5 px-4 text-slate-500">
                          {st.settledAt
                            ? new Date(st.settledAt).toLocaleDateString('en-IN', {
                                day: 'numeric',
                                month: 'short',
                                year: 'numeric',
                              })
                            : new Date(st.createdAt).toLocaleDateString()}
                        </td>

                        <td className="py-3.5 px-4">{getStatusBadge(st.status)}</td>

                        <td className="py-3.5 px-4 font-mono text-[11px] font-bold text-slate-700">
                          {st.utrReference || st.paymentReference || 'Auto Payout Scheduled'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* ─── Tab Content 2: Double-Entry Transaction Ledger ──────────────────── */}
        {activeTab === 'ledger' && (
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            {filteredEntries.length === 0 ? (
              <EmptyState
                title="No Ledger Entries Found"
                description="Real-time financial transactions, sales, commission snapshots, and adjustments will appear here."
              />
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 text-slate-500 font-bold uppercase text-[10px] tracking-wider border-b border-slate-100">
                    <tr>
                      <th className="py-3.5 px-4">Date & Time</th>
                      <th className="py-3.5 px-4">Transaction / Order</th>
                      <th className="py-3.5 px-4">Event Type</th>
                      <th className="py-3.5 px-4">Gross</th>
                      <th className="py-3.5 px-4">Commission</th>
                      <th className="py-3.5 px-4">Credit</th>
                      <th className="py-3.5 px-4">Debit</th>
                      <th className="py-3.5 px-4">Net Amount</th>
                      <th className="py-3.5 px-4">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium">
                    {filteredEntries.map((e) => {
                      const isCredit = Number(e.netAmount) >= 0;
                      return (
                        <tr key={e.id} className="hover:bg-slate-50/60 transition-colors">
                          <td className="py-3.5 px-4 text-slate-500 whitespace-nowrap">
                            {new Date(e.createdAt).toLocaleString('en-IN', {
                              day: 'numeric',
                              month: 'short',
                              hour: '2-digit',
                              minute: '2-digit',
                            })}
                          </td>

                          <td className="py-3.5 px-4">
                            <div className="flex flex-col">
                              <span className="font-mono font-bold text-slate-900">
                                #{e.sellerOrderId ? e.sellerOrderId.slice(0, 8).toUpperCase() : e.id.slice(0, 8).toUpperCase()}
                              </span>
                              <span className="text-[11px] text-slate-500 font-normal">
                                {e.description || (e.type === 'SALE' ? 'Wholesale Order Earning' : e.type)}
                              </span>
                            </div>
                          </td>

                          <td className="py-3.5 px-4">
                            <span
                              className={`inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold ${
                                e.type === 'SALE' || e.type === 'EARNING'
                                  ? 'bg-blue-50 text-blue-700'
                                  : e.type === 'REFUND'
                                  ? 'bg-rose-50 text-rose-700'
                                  : e.type === 'SETTLEMENT'
                                  ? 'bg-emerald-50 text-emerald-700'
                                  : 'bg-slate-100 text-slate-700'
                              }`}
                            >
                              {e.type}
                            </span>
                          </td>

                          <td className="py-3.5 px-4 font-semibold text-slate-800">
                            ₹{Number(e.grossAmount).toLocaleString('en-IN')}
                          </td>

                          <td className="py-3.5 px-4 font-semibold text-purple-700">
                            {Number(e.commissionAmount) > 0 ? `-₹${Number(e.commissionAmount).toLocaleString('en-IN')}` : '₹0'}
                          </td>

                          <td className="py-3.5 px-4 text-emerald-600 font-semibold">
                            {Number(e.credit) > 0 ? `+₹${Number(e.credit).toLocaleString('en-IN')}` : '-'}
                          </td>

                          <td className="py-3.5 px-4 text-rose-600 font-semibold">
                            {Number(e.debit) > 0 ? `-₹${Number(e.debit).toLocaleString('en-IN')}` : '-'}
                          </td>

                          <td className={`py-3.5 px-4 font-black text-sm ${isCredit ? 'text-emerald-600' : 'text-rose-600'}`}>
                            {isCredit ? '+' : ''}₹{Number(e.netAmount).toLocaleString('en-IN')}
                          </td>

                          <td className="py-3.5 px-4">{getStatusBadge(e.status)}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
