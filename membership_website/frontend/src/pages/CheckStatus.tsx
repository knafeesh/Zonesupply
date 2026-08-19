import { useState } from 'react';
import Navbar from '../components/Navbar';
import Footer from '../components/Footer';
import { checkApplicationStatus } from '../services/api';
import { ApplicationStatus } from '../types';

const STATUS_CONFIG = {
  pending: {
    label: 'Pending Verification',
    emoji: '⏳',
    colorCls: 'badge-pending',
    dotCls: 'bg-amber-400',
    bannerCls: 'bg-amber-50 border-amber-200',
    textCls: 'text-amber-700',
    desc: 'Your application is under review. Our team will process it within 2–3 business days.',
  },
  approved: {
    label: 'Approved ✓',
    emoji: '✅',
    colorCls: 'badge-approved',
    dotCls: 'bg-green-500',
    bannerCls: 'bg-green-50 border-green-200',
    textCls: 'text-green-700',
    desc: 'Congratulations! Your membership has been approved.',
  },
  rejected: {
    label: 'Not Approved',
    emoji: '❌',
    colorCls: 'badge-rejected',
    dotCls: 'bg-red-500',
    bannerCls: 'bg-red-50 border-red-200',
    textCls: 'text-red-700',
    desc: 'Unfortunately, your application could not be approved at this time.',
  },
};

const CheckStatus = () => {
  const [searchType, setSearchType] = useState<'applicationId' | 'mobile'>('applicationId');
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [result, setResult] = useState<ApplicationStatus | null>(null);

  const handleSearch = async () => {
    if (!query.trim()) { setError('Please enter a value to search'); return; }
    if (searchType === 'mobile' && !/^[6-9]\d{9}$/.test(query)) {
      setError('Enter a valid 10-digit mobile number'); return;
    }
    if (searchType === 'applicationId' && !query.startsWith('ZS-APP-')) {
      setError('Application ID format: ZS-APP-XXXXXX'); return;
    }

    setError(''); setLoading(true); setResult(null);
    try {
      const res = await checkApplicationStatus(
        searchType === 'applicationId' ? query : undefined,
        searchType === 'mobile' ? query : undefined,
      );
      if (res.success && res.data) setResult(res.data);
      else setError(res.message || 'No application found.');
    } catch (err: any) {
      setError(err?.response?.data?.message || 'No application found with those details.');
    } finally { setLoading(false); }
  };

  const cfg = result ? STATUS_CONFIG[result.status] : null;

  return (
    <div className="min-h-screen flex flex-col bg-[#F8FAFF]">
      <Navbar />

      {/* Page header */}
      <div className="bg-white border-b border-gray-100 py-8">
        <div className="max-w-3xl mx-auto px-4 text-center">
          <h1 className="text-2xl md:text-3xl font-black text-gray-900 mb-1">
            Check Application Status
          </h1>
          <p className="text-gray-400 text-sm">
            Search by your Application ID or registered mobile number
          </p>
        </div>
      </div>

      <div className="flex-1 max-w-2xl mx-auto w-full px-4 py-10 space-y-5">

        {/* Search Card */}
        <div className="card p-6 animate-fade-in">
          {/* Toggle */}
          <div className="flex bg-gray-100 rounded-xl p-1 mb-5 gap-1">
            {(['applicationId', 'mobile'] as const).map(type => (
              <button
                key={type}
                id={`toggle-${type}`}
                onClick={() => { setSearchType(type); setQuery(''); setError(''); setResult(null); }}
                className={`flex-1 py-2.5 rounded-lg text-sm font-semibold transition-all duration-200
                  ${searchType === type
                    ? 'bg-white text-brand-600 shadow-sm'
                    : 'text-gray-500 hover:text-gray-700'}`}
              >
                {type === 'applicationId' ? '🔑 Application ID' : '📱 Mobile Number'}
              </button>
            ))}
          </div>

          {/* Search Row */}
          <div className="flex gap-3">
            <div className="flex-1">
              {searchType === 'applicationId' ? (
                <input
                  id="search-app-id"
                  className="input-field"
                  placeholder="ZS-APP-000001"
                  value={query}
                  onChange={e => { setQuery(e.target.value.toUpperCase()); setError(''); }}
                  onKeyDown={e => e.key === 'Enter' && handleSearch()}
                />
              ) : (
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-medium text-sm select-none">+91</span>
                  <input
                    id="search-mobile"
                    className="input-field pl-12"
                    placeholder="9876543210"
                    value={query}
                    onChange={e => { setQuery(e.target.value.replace(/\D/g, '').slice(0, 10)); setError(''); }}
                    maxLength={10}
                    inputMode="numeric"
                    onKeyDown={e => e.key === 'Enter' && handleSearch()}
                  />
                </div>
              )}
              {error && <p className="error-text">{error}</p>}
            </div>

            <button
              id="search-btn"
              onClick={handleSearch}
              disabled={loading}
              className="btn-primary px-5 flex-shrink-0"
            >
              {loading ? (
                <svg className="w-5 h-5 spinner" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                </svg>
              ) : (
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
              )}
            </button>
          </div>
        </div>

        {/* Result Card */}
        {result && cfg && (
          <div className="card p-6 animate-slide-up">
            {/* Header row */}
            <div className="flex items-start justify-between mb-4">
              <div>
                <p className="text-[10px] text-gray-400 uppercase tracking-wider mb-1">Application ID</p>
                <h3 className="text-lg font-black text-brand-600">{result.applicationId}</h3>
              </div>
              <span className="text-3xl">{cfg.emoji}</span>
            </div>

            {/* Status */}
            <div className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold mb-4 ${cfg.colorCls}`}>
              <span className={`w-1.5 h-1.5 rounded-full animate-pulse-slow ${cfg.dotCls}`} />
              {cfg.label}
            </div>

            <p className="text-gray-500 text-sm mb-5">{cfg.desc}</p>

            {/* Details */}
            <div className="space-y-2.5 border-t border-gray-100 pt-4">
              {[
                { label: 'Applicant Name', value: result.fullName },
                { label: 'Shop Name',      value: result.shopName },
                { label: 'Submitted',      value: new Date(result.submittedAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' }) },
                { label: 'Last Updated',   value: new Date(result.updatedAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' }) },
              ].map(row => (
                <div key={row.label} className="flex justify-between text-sm">
                  <span className="text-gray-400">{row.label}</span>
                  <span className="font-semibold text-gray-800">{row.value}</span>
                </div>
              ))}
            </div>

            {/* Membership ID (approved) */}
            {result.status === 'approved' && result.membershipId && (
              <div className="mt-5 bg-green-50 border-2 border-green-200 rounded-2xl p-5 text-center">
                <p className="text-[10px] font-semibold text-green-600 uppercase tracking-widest mb-1">
                  Zone Store Membership ID
                </p>
                <p className="text-3xl font-black text-green-700 tracking-widest" id="membership-id">
                  {result.membershipId}
                </p>
                <p className="text-xs text-green-500 mt-2">🎉 Welcome to Zone Store's exclusive retailer network!</p>
              </div>
            )}

            {/* Rejection reason */}
            {result.status === 'rejected' && result.rejectionReason && (
              <div className="mt-5 bg-red-50 border border-red-200 rounded-xl p-4">
                <p className="text-sm font-semibold text-red-700 mb-1">Reason:</p>
                <p className="text-sm text-red-600">{result.rejectionReason}</p>
              </div>
            )}
          </div>
        )}

        <p className="text-center text-xs text-gray-400">
          Can't find your application?{' '}
          <a href="mailto:support@zonesupply.in" className="text-brand-500 hover:underline">
            support@zonesupply.in
          </a>
        </p>
      </div>

      <Footer />
    </div>
  );
};

export default CheckStatus;
