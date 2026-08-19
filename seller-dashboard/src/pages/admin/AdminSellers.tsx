import React, { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { EmptyState } from '../../components/common/EmptyState';
import { ConfirmDialog } from '../../components/common/ConfirmDialog';
import { adminService } from '../../services/adminService';
import { Wholesaler, SettlementCycle } from '../../types';
import {
  Users,
  Search,
  CheckCircle2,
  XCircle,
  Building,
  Phone,
  Mail,
  MapPin,
  Shield,
  Layers,
  ShoppingCart,
  Percent,
  Clock,
  Edit2,
  Save,
  X,
} from 'lucide-react';
import toast from 'react-hot-toast';

export const AdminSellers: React.FC = () => {
  const { onOpenSidebar } = useOutletContext<{ onOpenSidebar: () => void }>();

  const [sellers, setSellers] = useState<Wholesaler[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [toggleSeller, setToggleSeller] = useState<Wholesaler | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  // Edit commission / settlement modal state
  const [editingSeller, setEditingSeller] = useState<Wholesaler | null>(null);
  const [editCommission, setEditCommission] = useState<number>(5.0);
  const [editCycle, setEditCycle] = useState<SettlementCycle>('T_2');
  const [savingConfig, setSavingConfig] = useState(false);

  const fetchSellers = async () => {
    try {
      const data = await adminService.getAllSellers();
      setSellers(data);
    } catch {
      toast.error('Failed to load sellers');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSellers();
  }, []);

  const handleToggleStatus = async () => {
    if (!toggleSeller) return;
    setActionLoading(true);
    try {
      const res = await adminService.toggleSellerStatus(toggleSeller.id);
      toast.success(res.message);
      setToggleSeller(null);
      fetchSellers();
    } catch {
      toast.error('Failed to update seller status');
    } finally {
      setActionLoading(false);
    }
  };

  const handleSaveConfig = async () => {
    if (!editingSeller) return;
    setSavingConfig(true);
    try {
      await Promise.all([
        adminService.updateSellerCommission(editingSeller.id, editCommission),
        adminService.updateSettlementCycle(editingSeller.id, editCycle),
      ]);
      toast.success(`Updated settings for ${editingSeller.businessName}`);
      setEditingSeller(null);
      fetchSellers();
    } catch {
      toast.error('Failed to update seller configuration');
    } finally {
      setSavingConfig(false);
    }
  };

  const openEditModal = (seller: Wholesaler) => {
    setEditingSeller(seller);
    setEditCommission(Number(seller.commissionRate) || 5.0);
    setEditCycle(seller.settlementCycle || 'T_2');
  };

  const filteredSellers = sellers.filter((s) => {
    const q = searchQuery.toLowerCase();
    return (
      s.businessName.toLowerCase().includes(q) ||
      (s.user?.name && s.user.name.toLowerCase().includes(q)) ||
      (s.user?.email && s.user.email.toLowerCase().includes(q)) ||
      (s.gstNumber && s.gstNumber.toLowerCase().includes(q)) ||
      (s.address && s.address.toLowerCase().includes(q))
    );
  });

  return (
    <div className="flex flex-col min-h-screen bg-gray-50 pb-12">
      <Header
        onOpenSidebar={onOpenSidebar}
        title="Wholesale Sellers Directory"
        subtitle="Manage vendor credentials, verification, commission rates & automated settlement cycles"
      />

      <div className="px-4 sm:px-6 lg:px-8 py-6 space-y-6 max-w-7xl w-full mx-auto">
        {/* Search Bar */}
        <div className="bg-white p-3.5 rounded-2xl border border-gray-200 shadow-card flex items-center justify-between">
          <div className="relative flex-1 max-w-md">
            <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by business name, owner, email, GSTIN, or city..."
              className="w-full pl-9 pr-4 py-2 rounded-xl border border-gray-200 text-xs focus:outline-none focus:ring-2 focus:ring-brand-500 font-medium"
            />
          </div>

          <div className="flex items-center gap-2 text-xs font-bold text-gray-500">
            <span>Total Sellers: {sellers.length}</span>
          </div>
        </div>

        {/* Table */}
        {loading ? (
          <LoadingSpinner message="Auditing wholesale sellers..." />
        ) : filteredSellers.length === 0 ? (
          <EmptyState
            title="No Sellers Found"
            description="No wholesale sellers match your query."
          />
        ) : (
          <div className="bg-white rounded-2xl border border-gray-200 shadow-card overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-gray-50/80 text-gray-500 font-bold uppercase text-[10px] tracking-wider border-b border-gray-100">
                  <tr>
                    <th className="py-3.5 px-4">Wholesale Business</th>
                    <th className="py-3.5 px-4">Contact Info</th>
                    <th className="py-3.5 px-4">Commission</th>
                    <th className="py-3.5 px-4">Payout Cycle</th>
                    <th className="py-3.5 px-4">Products</th>
                    <th className="py-3.5 px-4">Status</th>
                    <th className="py-3.5 px-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 font-medium">
                  {filteredSellers.map((seller) => {
                    const isActive = seller.user?.isActive ?? true;

                    return (
                      <tr key={seller.id} className="hover:bg-gray-50/60 transition-colors">
                        <td className="py-3.5 px-4">
                          <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-xl bg-brand-50 border border-brand-100 flex items-center justify-center text-brand-700 font-black text-xs shrink-0">
                              {seller.businessName.charAt(0)}
                            </div>
                            <div className="flex flex-col">
                              <span className="font-extrabold text-gray-900 text-sm">
                                {seller.businessName}
                              </span>
                              <span className="text-[10px] text-gray-400">
                                Owner: {seller.user?.name || 'Seller'} • {seller.zone?.name || 'All Zones'}
                              </span>
                            </div>
                          </div>
                        </td>

                        <td className="py-3.5 px-4">
                          <div className="flex flex-col text-gray-600">
                            <span className="flex items-center gap-1">
                              <Mail className="w-3 h-3 text-gray-400" />
                              {seller.user?.email}
                            </span>
                            {seller.user?.phone && (
                              <span className="flex items-center gap-1 text-[10px] text-gray-400">
                                <Phone className="w-3 h-3 text-gray-400" />
                                {seller.user.phone}
                              </span>
                            )}
                          </div>
                        </td>

                        <td className="py-3.5 px-4">
                          <div className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-purple-50 text-purple-700 font-bold text-xs">
                            <Percent className="w-3 h-3" />
                            {seller.commissionRate ?? 5.0}%
                          </div>
                        </td>

                        <td className="py-3.5 px-4">
                          <div className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-blue-50 text-blue-700 font-bold text-xs">
                            <Clock className="w-3 h-3" />
                            {seller.settlementCycle ? seller.settlementCycle.replace('_', '+') : 'T+2'}
                          </div>
                        </td>

                        <td className="py-3.5 px-4">
                          <span className="px-2 py-0.5 rounded-lg bg-slate-100 text-slate-700 font-extrabold text-xs">
                            {seller.productCount || 0} Items
                          </span>
                        </td>

                        <td className="py-3.5 px-4">
                          {isActive ? (
                            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                              <CheckCircle2 className="w-3.5 h-3.5" />
                              Active
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-50 text-rose-700 border border-rose-200">
                              <XCircle className="w-3.5 h-3.5" />
                              Suspended
                            </span>
                          )}
                        </td>

                        <td className="py-3.5 px-4 text-right space-x-2">
                          <button
                            onClick={() => openEditModal(seller)}
                            className="py-1.5 px-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs transition-colors"
                            title="Edit Commission & Payout Timing"
                          >
                            <Edit2 className="w-3.5 h-3.5 inline mr-1" />
                            Fee & Payout
                          </button>

                          <button
                            onClick={() => setToggleSeller(seller)}
                            className={`py-1.5 px-3 rounded-xl font-bold text-xs transition-all ${
                              isActive
                                ? 'bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200'
                                : 'bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-200'
                            }`}
                          >
                            {isActive ? 'Suspend' : 'Activate'}
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* Commission & Settlement Modal */}
      {editingSeller && (
        <div className="fixed inset-0 z-50 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4 animate-fade-in">
          <div className="bg-white rounded-3xl p-6 max-w-md w-full shadow-2xl border border-slate-100 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div>
                <h3 className="text-base font-extrabold text-slate-900">
                  Seller Commission & Settlement
                </h3>
                <p className="text-xs text-slate-500 font-medium">{editingSeller.businessName}</p>
              </div>
              <button
                onClick={() => setEditingSeller(null)}
                className="p-1 text-slate-400 hover:text-slate-600 rounded-lg"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Platform Commission Rate (%)
                </label>
                <div className="relative">
                  <Percent className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="number"
                    step="0.1"
                    min="0"
                    max="100"
                    value={editCommission}
                    onChange={(e) => setEditCommission(parseFloat(e.target.value) || 0)}
                    className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 text-sm font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
                <p className="text-[11px] text-slate-400 mt-1">
                  Applied to new transactions. Historical orders retain their locked snapshot.
                </p>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Settlement Payout Schedule
                </label>
                <select
                  value={editCycle}
                  onChange={(e) => setEditCycle(e.target.value as SettlementCycle)}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm font-bold text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-brand-500"
                >
                  <option value="T_1">T+1 (Next business day after delivery)</option>
                  <option value="T_2">T+2 (2 business days after delivery - Default)</option>
                  <option value="T_7">T+7 (Weekly payout batch)</option>
                  <option value="MANUAL">Manual Settlement (Admin approved only)</option>
                </select>
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setEditingSeller(null)}
                className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleSaveConfig}
                disabled={savingConfig}
                className="flex items-center gap-1.5 px-5 py-2 rounded-xl bg-brand-500 hover:bg-brand-600 text-white font-bold text-xs shadow-btn-primary transition-all disabled:opacity-50"
              >
                {savingConfig ? (
                  <>
                    <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    <span>Saving...</span>
                  </>
                ) : (
                  <>
                    <Save className="w-3.5 h-3.5" />
                    <span>Save Settings</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Confirm Suspend/Activate */}
      <ConfirmDialog
        isOpen={!!toggleSeller}
        title={
          toggleSeller?.user?.isActive
            ? 'Suspend Wholesale Seller?'
            : 'Activate Wholesale Seller?'
        }
        message={
          toggleSeller?.user?.isActive
            ? `Suspending "${toggleSeller?.businessName}" will immediately hide their catalog from the Retailer App and freeze pending order dispatch.`
            : `Activating "${toggleSeller?.businessName}" will restore their wholesale catalog and order fulfillment capabilities.`
        }
        confirmText={toggleSeller?.user?.isActive ? 'Suspend Seller' : 'Activate Seller'}
        isDangerous={toggleSeller?.user?.isActive}
        isLoading={actionLoading}
        onConfirm={handleToggleStatus}
        onClose={() => setToggleSeller(null)}
      />
    </div>
  );
};
