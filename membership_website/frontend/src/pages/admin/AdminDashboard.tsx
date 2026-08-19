import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAdminAuth } from '../../context/AdminAuthContext';
import { getAdminApplications, getAdminApplicationById, approveApplication, rejectApplication } from '../../services/api';
import { AdminApplication, AdminStats } from '../../types';
import toast from 'react-hot-toast';

type FilterStatus = 'all' | 'pending' | 'approved' | 'rejected';

const AdminDashboard = () => {
  const navigate = useNavigate();
  const { admin, logout } = useAdminAuth();
  const [applications, setApplications] = useState<AdminApplication[]>([]);
  const [stats, setStats] = useState<AdminStats>({ total: 0, pending: 0, approved: 0, rejected: 0 });
  const [filter, setFilter] = useState<FilterStatus>('all');
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<AdminApplication | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [rejectReason, setRejectReason] = useState('');
  const [showRejectModal, setShowRejectModal] = useState(false);

  const fetchApplications = useCallback(async () => {
    setLoading(true);
    try {
      const res = await getAdminApplications(filter === 'all' ? undefined : filter);
      if (res.success) {
        setApplications(res.data || []);
        setStats(res.stats);
      }
    } catch {
      toast.error('Failed to load applications');
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => { fetchApplications(); }, [fetchApplications]);

  const viewApplication = async (id: string) => {
    setDetailLoading(true);
    try {
      const res = await getAdminApplicationById(id);
      if (res.success) setSelected(res.data || null);
    } catch {
      toast.error('Failed to load application details');
    } finally {
      setDetailLoading(false);
    }
  };

  const handleApprove = async () => {
    if (!selected) return;
    setActionLoading(true);
    try {
      const res = await approveApplication(selected.application_id);
      if (res.success) {
        toast.success(`Approved! Membership ID: ${res.data?.membershipId}`);
        setSelected(null);
        fetchApplications();
      } else {
        toast.error(res.message || 'Approval failed');
      }
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Action failed');
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!selected || !rejectReason.trim()) { toast.error('Please enter a rejection reason'); return; }
    setActionLoading(true);
    try {
      const res = await rejectApplication(selected.application_id, rejectReason);
      if (res.success) {
        toast.success('Application rejected');
        setSelected(null);
        setShowRejectModal(false);
        setRejectReason('');
        fetchApplications();
      } else {
        toast.error(res.message || 'Rejection failed');
      }
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Action failed');
    } finally {
      setActionLoading(false);
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/admin');
  };

  const STAT_CARDS = [
    { label: 'Total Applications', value: stats.total, color: 'brand', icon: '📋' },
    { label: 'Pending Review', value: stats.pending, color: 'amber', icon: '⏳' },
    { label: 'Approved', value: stats.approved, color: 'green', icon: '✅' },
    { label: 'Rejected', value: stats.rejected, color: 'red', icon: '❌' },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Admin Topbar */}
      <header className="bg-brand-900 text-white shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="w-10 h-10 rounded-xl bg-brand-600 flex items-center justify-center font-black text-sm">ZS</div>
            <div>
              <div className="font-bold text-white text-sm">Zone Store Admin</div>
              <div className="text-brand-300 text-xs">Membership Management</div>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-brand-300 text-sm hidden sm:block">👤 {admin?.username}</span>
            <button id="admin-logout-btn" onClick={handleLogout}
              className="px-4 py-2 rounded-lg bg-white/10 hover:bg-white/20 text-white text-sm font-medium transition-colors duration-150">
              Sign Out
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          {STAT_CARDS.map(s => (
            <div key={s.label} className="card p-5">
              <div className="text-2xl mb-2">{s.icon}</div>
              <div className="text-2xl font-black text-gray-900">{s.value}</div>
              <div className="text-xs text-gray-500 mt-1">{s.label}</div>
            </div>
          ))}
        </div>

        {/* Filter Tabs */}
        <div className="flex bg-white rounded-xl border border-gray-200 p-1 gap-1 mb-4 w-fit">
          {(['all', 'pending', 'approved', 'rejected'] as FilterStatus[]).map(f => (
            <button
              key={f}
              id={`filter-${f}`}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 rounded-lg text-sm font-semibold capitalize transition-all duration-150
                ${filter === f ? 'bg-brand-600 text-white shadow-sm' : 'text-gray-500 hover:text-gray-800'}`}
            >
              {f} {f !== 'all' && stats[f as keyof AdminStats] > 0 && (
                <span className={`ml-1 px-1.5 py-0.5 rounded-full text-xs
                  ${filter === f ? 'bg-white/20' : 'bg-gray-100'}`}>
                  {stats[f as keyof AdminStats]}
                </span>
              )}
            </button>
          ))}
        </div>

        {/* Applications Table */}
        <div className="card overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center py-16 text-gray-400">
              <svg className="w-8 h-8 spinner mr-3" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
              </svg>
              Loading applications...
            </div>
          ) : applications.length === 0 ? (
            <div className="text-center py-16 text-gray-400">
              <div className="text-4xl mb-3">📭</div>
              <p className="font-medium">No {filter !== 'all' ? filter : ''} applications found</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-gray-50 border-b border-gray-100">
                  <tr>
                    {['Application ID', 'Applicant', 'Shop', 'Location', 'Status', 'Date', 'Action'].map(h => (
                      <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {applications.map(app => (
                    <tr key={app.application_id} className="hover:bg-brand-50/50 transition-colors duration-100">
                      <td className="px-4 py-3 font-mono text-brand-600 font-semibold text-xs">{app.application_id}</td>
                      <td className="px-4 py-3">
                        <div className="font-semibold text-gray-900">{app.full_name}</div>
                        <div className="text-gray-400 text-xs">{app.mobile}</div>
                      </td>
                      <td className="px-4 py-3 text-gray-700">{app.shop_name}</td>
                      <td className="px-4 py-3 text-gray-500">{app.city}, {app.state}</td>
                      <td className="px-4 py-3">
                        <span className={app.status === 'pending' ? 'badge-pending' : app.status === 'approved' ? 'badge-approved' : 'badge-rejected'}>
                          {app.status}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-gray-400 text-xs">
                        {new Date(app.created_at).toLocaleDateString('en-IN')}
                      </td>
                      <td className="px-4 py-3">
                        <button
                          id={`view-${app.application_id}`}
                          onClick={() => viewApplication(app.application_id)}
                          className="text-brand-600 hover:text-brand-800 font-semibold text-xs hover:underline"
                        >
                          View →
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* ── Application Detail Drawer ── */}
      {(selected || detailLoading) && (
        <div className="fixed inset-0 z-50 flex">
          <div className="flex-1 bg-black/40 backdrop-blur-sm" onClick={() => setSelected(null)} />
          <div className="w-full max-w-lg bg-white shadow-2xl overflow-y-auto animate-slide-up">
            <div className="sticky top-0 bg-white border-b border-gray-100 px-6 py-4 flex items-center justify-between z-10">
              <h2 className="font-bold text-gray-900">Application Details</h2>
              <button onClick={() => setSelected(null)} className="text-gray-400 hover:text-gray-700 text-xl">✕</button>
            </div>

            {detailLoading ? (
              <div className="flex items-center justify-center py-20 text-gray-400">Loading...</div>
            ) : selected && (
              <div className="p-6 space-y-6">
                {/* Status */}
                <div className="flex items-center justify-between">
                  <span className={selected.status === 'pending' ? 'badge-pending' : selected.status === 'approved' ? 'badge-approved' : 'badge-rejected'}>
                    {selected.status.toUpperCase()}
                  </span>
                  <span className="text-xs text-gray-400 font-mono">{selected.application_id}</span>
                </div>

                {/* Membership ID if approved */}
                {selected.status === 'approved' && selected.membership_id && (
                  <div className="bg-green-50 border border-green-200 rounded-xl p-4 text-center">
                    <p className="text-xs text-green-600 font-semibold uppercase tracking-wider mb-1">Membership ID</p>
                    <p className="text-2xl font-black text-green-700">{selected.membership_id}</p>
                  </div>
                )}

                {/* Info sections */}
                <Section title="Personal Information">
                  <Row label="Full Name" value={selected.full_name} />
                  <Row label="Mobile" value={selected.mobile} />
                  <Row label="Email" value={selected.email} />
                </Section>
                <Section title="Business Details">
                  <Row label="Shop Name" value={selected.shop_name} />
                  <Row label="Business Type" value={selected.business_type} />
                  {selected.gst_number && <Row label="GST Number" value={selected.gst_number} />}
                  <Row label="Address" value={selected.address || '—'} />
                  <Row label="City / State" value={`${selected.city}, ${selected.state}`} />
                  <Row label="Pincode" value={selected.pincode || '—'} />
                </Section>
                {selected.documents && selected.documents.length > 0 && (
                  <Section title="Documents">
                    {selected.documents.map(doc => (
                      <div key={doc.doc_type} className="flex items-center justify-between py-1">
                        <span className="text-sm text-gray-500 capitalize">{doc.doc_type.replace('_', ' ')}</span>
                        <a href={`/uploads/${doc.file_path.split('/').pop()}`} target="_blank" rel="noopener noreferrer"
                          className="text-xs text-brand-600 hover:underline font-semibold">
                          View →
                        </a>
                      </div>
                    ))}
                  </Section>
                )}
                {selected.rejection_reason && (
                  <div className="bg-red-50 border border-red-200 rounded-xl p-4">
                    <p className="text-sm font-semibold text-red-700 mb-1">Rejection Reason</p>
                    <p className="text-sm text-red-600">{selected.rejection_reason}</p>
                  </div>
                )}

                {/* Actions - only for pending */}
                {selected.status === 'pending' && (
                  <div className="flex gap-3 pt-2 border-t border-gray-100">
                    <button
                      id={`approve-${selected.application_id}`}
                      onClick={handleApprove}
                      disabled={actionLoading}
                      className="flex-1 py-3 rounded-xl bg-green-600 hover:bg-green-700 text-white font-bold
                                 transition-all duration-200 disabled:opacity-60 text-sm"
                    >
                      {actionLoading ? '...' : '✅ Approve & Generate ID'}
                    </button>
                    <button
                      id={`reject-${selected.application_id}`}
                      onClick={() => setShowRejectModal(true)}
                      disabled={actionLoading}
                      className="flex-1 py-3 rounded-xl bg-red-50 hover:bg-red-100 border border-red-200 text-red-600 font-bold
                                 transition-all duration-200 disabled:opacity-60 text-sm"
                    >
                      ❌ Reject
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      )}

      {/* ── Reject Reason Modal ── */}
      {showRejectModal && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/50" onClick={() => setShowRejectModal(false)} />
          <div className="relative bg-white rounded-2xl p-6 w-full max-w-md shadow-2xl animate-fade-in">
            <h3 className="font-bold text-gray-900 mb-4">Rejection Reason</h3>
            <textarea
              id="reject-reason-input"
              className="input-field resize-none mb-4"
              rows={4}
              placeholder="Explain why this application is being rejected..."
              value={rejectReason}
              onChange={e => setRejectReason(e.target.value)}
            />
            <div className="flex gap-3">
              <button onClick={() => setShowRejectModal(false)}
                className="flex-1 btn-secondary text-sm py-2.5">
                Cancel
              </button>
              <button
                id="confirm-reject-btn"
                onClick={handleReject}
                disabled={actionLoading || !rejectReason.trim()}
                className="flex-1 py-2.5 rounded-xl bg-red-600 hover:bg-red-700 text-white font-bold text-sm
                           transition-all duration-200 disabled:opacity-60">
                {actionLoading ? 'Processing...' : 'Confirm Reject'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

// Helpers
const Section = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <div>
    <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-3">{title}</h3>
    <div className="space-y-2">{children}</div>
  </div>
);
const Row = ({ label, value }: { label: string; value: string }) => (
  <div className="flex gap-3 text-sm">
    <span className="text-gray-400 min-w-[100px]">{label}</span>
    <span className="text-gray-900 font-medium">{value}</span>
  </div>
);

export default AdminDashboard;
