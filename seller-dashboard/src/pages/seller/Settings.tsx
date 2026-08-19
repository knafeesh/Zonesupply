import React, { useState, useEffect, useRef } from 'react';
import { useOutletContext } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { wholesalerService } from '../../services/wholesalerService';
import { Wholesaler, WholesalerPaymentAccount } from '../../types';
import { useAuth } from '../../auth/AuthContext';
import {
  Building,
  Phone,
  User,
  MapPin,
  ShieldCheck,
  Save,
  Mail,
  Upload,
  Camera,
  Compass,
  FileText,
  CreditCard,
  Store,
  ExternalLink,
  CheckCircle2,
  Trash2,
  Sparkles,
  AlertCircle,
} from 'lucide-react';
import toast from 'react-hot-toast';

export const Settings: React.FC = () => {
  const { onOpenSidebar } = useOutletContext<{ onOpenSidebar: () => void }>();
  const { user, refreshUser } = useAuth();

  const [profile, setProfile] = useState<Wholesaler | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [gettingLocation, setGettingLocation] = useState(false);

  // Payment account state
  const [paymentAccount, setPaymentAccount] = useState<WholesalerPaymentAccount | null>(null);
  const [paymentData, setPaymentData] = useState({
    beneficiaryName: '',
    accountNumber: '',  // full account for writes (won't be masked)
    ifscCode: '',
    bankName: '',
    vpaId: '',
  });
  const [savingPayment, setSavingPayment] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    profilePicture: '',
    businessName: '',
    gstNumber: '',
    panNumber: '',
    address: '',
    shopNumber: '',
    latitude: 0,
    longitude: 0,
  });

  const loadProfile = async () => {
    try {
      const data = await wholesalerService.getProfile();
      setProfile(data);
      setFormData({
        name: data.user?.name || user?.name || '',
        email: data.user?.email || user?.email || '',
        phone: data.user?.phone || user?.phone || '',
        profilePicture: data.user?.profilePicture || user?.profilePicture || '',
        businessName: data.businessName || '',
        gstNumber: data.gstNumber || '',
        panNumber: data.panNumber || '',
        address: data.address || '',
        shopNumber: data.shopNumber || '',
        latitude: typeof data.latitude === 'number' ? data.latitude : parseFloat(`${data.latitude || 0}`),
        longitude: typeof data.longitude === 'number' ? data.longitude : parseFloat(`${data.longitude || 0}`),
      });
    } catch {
      toast.error('Failed to load profile');
    } finally {
      setLoading(false);
    }
  };

  const loadPaymentAccount = async () => {
    try {
      const data = await wholesalerService.getPaymentAccount();
      setPaymentAccount(data);
      setPaymentData({
        beneficiaryName: data.beneficiaryName || '',
        accountNumber: '',  // never pre-fill account number for security
        ifscCode: data.ifscCode || '',
        bankName: data.bankName || '',
        vpaId: data.vpaId || '',
      });
    } catch {
      // silently fail, state stays empty
    }
  };

  const handleSavePaymentAccount = async () => {
    setSavingPayment(true);
    try {
      const updated = await wholesalerService.updatePaymentAccount(paymentData);
      setPaymentAccount(updated);
      toast.success('Payment account updated successfully');
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to update payment account');
    } finally {
      setSavingPayment(false);
    }
  };

  useEffect(() => {
    loadProfile();
    loadPaymentAccount();
  }, []);

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      toast.error('Please upload a valid image file (PNG, JPG, WEBP)');
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      toast.error('Image size must be less than 5MB');
      return;
    }

    setUploadingImage(true);
    try {
      const res = await wholesalerService.uploadImage(file);
      const imageUrl = res.url;
      setFormData((prev) => ({ ...prev, profilePicture: imageUrl }));
      toast.success('Store profile photo uploaded! Click Save to apply.');
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to upload photo');
    } finally {
      setUploadingImage(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const handleDetectLocation = () => {
    if (!navigator.geolocation) {
      toast.error('Geolocation is not supported by your browser');
      return;
    }

    setGettingLocation(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setFormData((prev) => ({
          ...prev,
          latitude: parseFloat(pos.coords.latitude.toFixed(6)),
          longitude: parseFloat(pos.coords.longitude.toFixed(6)),
        }));
        setGettingLocation(false);
        toast.success(`Location pinned: ${pos.coords.latitude.toFixed(4)}, ${pos.coords.longitude.toFixed(4)}`);
      },
      (err) => {
        setGettingLocation(false);
        toast.error(`Location error: ${err.message}. You can enter coordinates manually.`);
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      await wholesalerService.updateProfile({
        name: formData.name,
        email: formData.email,
        phone: formData.phone,
        profilePicture: formData.profilePicture,
        businessName: formData.businessName,
        gstNumber: formData.gstNumber,
        panNumber: formData.panNumber,
        address: formData.address,
        shopNumber: formData.shopNumber,
        latitude: formData.latitude,
        longitude: formData.longitude,
      });

      await refreshUser();
      toast.success('Store profile updated successfully');
      loadProfile();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to update profile');
    } finally {
      setSaving(false);
    }
  };

  const getFullImageUrl = (path?: string) => {
    if (!path) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return `http://10.225.158.51:3000${path}`;
    return path;
  };

  const avatarPresets = [
    { label: 'Storefront', url: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=300&auto=format&fit=crop&q=80' },
    { label: 'Warehouse', url: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=300&auto=format&fit=crop&q=80' },
    { label: 'Fashion Hub', url: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300&auto=format&fit=crop&q=80' },
    { label: 'Grocery Mill', url: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300&auto=format&fit=crop&q=80' },
  ];

  if (loading) {
    return (
      <div className="flex flex-col h-full">
        <Header onOpenSidebar={onOpenSidebar} title="Store Profile & Settings" />
        <LoadingSpinner message="Loading profile..." />
      </div>
    );
  }

  const avatarUrl = getFullImageUrl(formData.profilePicture);

  return (
    <div className="flex flex-col min-h-screen bg-slate-50/60 pb-16">
      <Header
        onOpenSidebar={onOpenSidebar}
        title="Store Profile & Settings"
        subtitle="Manage your wholesale business identity, owner contacts, GSTIN & GPS store location"
      />

      <div className="px-4 sm:px-6 lg:px-8 py-6 max-w-4xl w-full mx-auto space-y-6">
        {/* Top Profile Summary Banner */}
        <div className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-slate-900 via-slate-800 to-brand-900 text-white p-6 sm:p-8 shadow-[0_8px_30px_rgba(0,0,0,0.12)]">
          <div className="absolute right-0 top-0 bottom-0 w-1/3 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-brand-500/20 via-transparent to-transparent pointer-events-none"></div>

          <div className="relative flex flex-col sm:flex-row items-center sm:items-start gap-6">
            {/* Avatar with Upload button */}
            <div className="relative group shrink-0">
              <div className="w-24 h-24 sm:w-28 sm:h-28 rounded-2xl overflow-hidden bg-white/10 border-2 border-white/20 shadow-xl flex items-center justify-center backdrop-blur-sm">
                {avatarUrl ? (
                  <img
                    src={avatarUrl}
                    alt={formData.businessName || 'Store Avatar'}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).src =
                        'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=300&auto=format&fit=crop&q=80';
                    }}
                  />
                ) : (
                  <div className="flex flex-col items-center justify-center text-white/70">
                    <Store className="w-10 h-10 mb-1" />
                    <span className="text-[10px] font-bold uppercase tracking-wider">No Photo</span>
                  </div>
                )}
              </div>

              {/* Upload trigger */}
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                disabled={uploadingImage}
                className="absolute -bottom-2 -right-2 p-2 rounded-xl bg-brand-500 hover:bg-brand-600 text-white shadow-lg border-2 border-slate-900 transition-all hover:scale-105 active:scale-95 disabled:opacity-50"
                title="Change Store Photo"
              >
                {uploadingImage ? (
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                ) : (
                  <Camera className="w-4 h-4" />
                )}
              </button>

              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handleImageUpload}
                className="hidden"
              />
            </div>

            {/* Business & Owner Info */}
            <div className="flex-1 text-center sm:text-left space-y-2">
              <div className="flex flex-wrap items-center justify-center sm:justify-start gap-2">
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase tracking-wider bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 flex items-center gap-1">
                  <CheckCircle2 className="w-3 h-3" />
                  Verified Wholesale Merchant
                </span>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-semibold bg-white/10 text-white/80 border border-white/10">
                  Zone: {profile?.zone?.name || 'Active Zone'}
                </span>
              </div>

              <h2 className="text-xl sm:text-2xl font-black tracking-tight text-white">
                {formData.businessName || 'Wholesale Store'}
              </h2>

              <p className="text-xs sm:text-sm text-slate-300 font-medium flex items-center justify-center sm:justify-start gap-2">
                <User className="w-3.5 h-3.5 text-brand-400" />
                Owner: {formData.name || 'Merchant Owner'}
                <span className="text-white/40">·</span>
                <Mail className="w-3.5 h-3.5 text-brand-400" />
                {formData.email || 'No email set'}
              </p>

              <div className="pt-1 text-[11px] text-slate-400 font-mono">
                Seller ID: #{profile?.id?.slice(0, 8).toUpperCase() || 'ZS-SELLER'} · Registered Store
              </div>
            </div>
          </div>
        </div>

        {/* Main Edit Form */}
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* 1. STORE PHOTO & LOGO SELECTION */}
          <div className="bg-white p-6 sm:p-7 rounded-3xl border border-slate-200/80 shadow-[0_2px_12px_rgba(0,0,0,0.03)] space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-xl bg-brand-50 text-brand-600">
                  <Camera className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Store Profile Picture & Logo</h3>
                  <p className="text-xs text-slate-500">Displayed in Retailer mobile app directory & storefront</p>
                </div>
              </div>

              {formData.profilePicture && (
                <button
                  type="button"
                  onClick={() => setFormData({ ...formData, profilePicture: '' })}
                  className="flex items-center gap-1 text-xs font-semibold text-rose-600 hover:text-rose-700"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                  Remove
                </button>
              )}
            </div>

            <div className="space-y-3">
              <div className="flex gap-2">
                <input
                  type="text"
                  value={formData.profilePicture}
                  onChange={(e) => setFormData({ ...formData, profilePicture: e.target.value })}
                  placeholder="Paste direct Image URL or upload a file below"
                  className="flex-1 px-3.5 py-2 rounded-xl border border-slate-200 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-brand-500 font-medium"
                />
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={uploadingImage}
                  className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs shadow-sm transition-all disabled:opacity-50"
                >
                  <Upload className="w-3.5 h-3.5" />
                  <span>{uploadingImage ? 'Uploading...' : 'Upload File'}</span>
                </button>
              </div>

              {/* Presets */}
              <div className="flex items-center gap-2 pt-1 flex-wrap">
                <span className="text-[11px] font-semibold text-slate-500 flex items-center gap-1">
                  <Sparkles className="w-3 h-3 text-amber-500" /> Or pick a studio preset:
                </span>
                {avatarPresets.map((preset) => (
                  <button
                    key={preset.label}
                    type="button"
                    onClick={() => setFormData({ ...formData, profilePicture: preset.url })}
                    className="px-2.5 py-1 rounded-lg text-[11px] font-bold bg-slate-100 hover:bg-brand-50 hover:text-brand-600 text-slate-700 border border-slate-200/80 transition-colors"
                  >
                    {preset.label}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* 2. OWNER CONTACT DETAILS */}
          <div className="bg-white p-6 sm:p-7 rounded-3xl border border-slate-200/80 shadow-[0_2px_12px_rgba(0,0,0,0.03)] space-y-4">
            <div className="flex items-center gap-2.5 border-b border-slate-100 pb-3">
              <div className="p-2 rounded-xl bg-blue-50 text-blue-600">
                <User className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-slate-900">Owner & Contact Details</h3>
                <p className="text-xs text-slate-500">Contact information used for orders, buyer chats & SMS alerts</p>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Owner Full Name *
                </label>
                <div className="relative">
                  <User className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="John Doe"
                    className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Email Address *
                </label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    placeholder="john@wholesale.com"
                    className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Phone / WhatsApp *
                </label>
                <div className="relative">
                  <Phone className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="tel"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    placeholder="9876543210"
                    className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
              </div>
            </div>
          </div>

          {/* 3. WHOLESALE STORE REGISTRATION CREDENTIALS */}
          <div className="bg-white p-6 sm:p-7 rounded-3xl border border-slate-200/80 shadow-[0_2px_12px_rgba(0,0,0,0.03)] space-y-4">
            <div className="flex items-center gap-2.5 border-b border-slate-100 pb-3">
              <div className="p-2 rounded-xl bg-purple-50 text-purple-600">
                <Building className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-slate-900">Wholesale Store & Tax Credentials</h3>
                <p className="text-xs text-slate-500">Business identification and invoice billing details</p>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Wholesale Business Name *
                </label>
                <div className="relative">
                  <Building className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    required
                    value={formData.businessName}
                    onChange={(e) => setFormData({ ...formData, businessName: e.target.value })}
                    placeholder="Gupta Wholesale Traders"
                    className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Shop / Warehouse Number
                </label>
                <div className="relative">
                  <Store className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    value={formData.shopNumber}
                    onChange={(e) => setFormData({ ...formData, shopNumber: e.target.value })}
                    placeholder="G-12, Wholesale Mandi Complex"
                    className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  GST Number (GSTIN)
                </label>
                <div className="relative">
                  <FileText className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    value={formData.gstNumber}
                    onChange={(e) => setFormData({ ...formData, gstNumber: e.target.value.toUpperCase() })}
                    placeholder="07AAAAA0000A1Z5"
                    className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-medium font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  PAN Card Number
                </label>
                <div className="relative">
                  <CreditCard className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    value={formData.panNumber}
                    onChange={(e) => setFormData({ ...formData, panNumber: e.target.value.toUpperCase() })}
                    placeholder="ABCDE1234F"
                    className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-medium font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
              </div>
            </div>
          </div>

          {/* 4. ADDRESS & GEO-LOCATION PINNING */}
          <div className="bg-white p-6 sm:p-7 rounded-3xl border border-slate-200/80 shadow-[0_2px_12px_rgba(0,0,0,0.03)] space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-xl bg-emerald-50 text-emerald-600">
                  <MapPin className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Physical Address & Store GPS Pin</h3>
                  <p className="text-xs text-slate-500">Allows nearby retail shop owners to discover your warehouse distance</p>
                </div>
              </div>

              <button
                type="button"
                onClick={handleDetectLocation}
                disabled={gettingLocation}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-50 hover:bg-emerald-100/80 text-emerald-700 text-xs font-bold border border-emerald-200 transition-colors disabled:opacity-50"
              >
                <Compass className="w-3.5 h-3.5 animate-spin" style={{ animationDuration: gettingLocation ? '1s' : '0s' }} />
                <span>{gettingLocation ? 'Detecting...' : 'Auto-Detect GPS'}</span>
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Warehouse / Physical Address *
                </label>
                <div className="relative">
                  <MapPin className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                  <textarea
                    rows={2}
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    placeholder="Plot 42, Sector 18, Near Wholesale Grain Market, Gurugram, Haryana - 122001"
                    className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                    Latitude (GPS)
                  </label>
                  <input
                    type="number"
                    step="0.000001"
                    value={formData.latitude || ''}
                    onChange={(e) => setFormData({ ...formData, latitude: parseFloat(e.target.value) || 0 })}
                    placeholder="28.459497"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-mono font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                    Longitude (GPS)
                  </label>
                  <input
                    type="number"
                    step="0.000001"
                    value={formData.longitude || ''}
                    onChange={(e) => setFormData({ ...formData, longitude: parseFloat(e.target.value) || 0 })}
                    placeholder="77.026638"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-mono font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
              </div>

              {formData.latitude !== 0 && formData.longitude !== 0 && (
                <div className="flex items-center justify-between p-3 rounded-xl bg-slate-50 border border-slate-200 text-xs text-slate-600">
                  <span>📍 Coordinates: {formData.latitude}, {formData.longitude}</span>
                  <a
                    href={`https://www.google.com/maps?q=${formData.latitude},${formData.longitude}`}
                    target="_blank"
                    rel="noreferrer"
                    className="flex items-center gap-1 font-bold text-brand-600 hover:text-brand-700 hover:underline"
                  >
                    <span>View on Google Maps</span>
                    <ExternalLink className="w-3 h-3" />
                  </a>
                </div>
              )}
            </div>
          </div>

          {/* 5. PAYMENT & SETTLEMENT ACCOUNT */}
          <div className="bg-white p-6 sm:p-7 rounded-3xl border border-slate-200/80 shadow-[0_2px_12px_rgba(0,0,0,0.03)] space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-xl bg-purple-50 text-purple-600">
                  <CreditCard className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Payment & Settlement Payout Account</h3>
                  <p className="text-xs text-slate-500">Verified bank account & UPI VPA used for automated payout transfers</p>
                </div>
              </div>

              {paymentAccount?.isVerified ? (
                <div className="flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  <span>Verified & Active</span>
                </div>
              ) : (
                <div className="flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-50 text-amber-700 border border-amber-200">
                  <AlertCircle className="w-3.5 h-3.5" />
                  <span>{paymentAccount?.status === 'NOT_CONFIGURED' ? 'Not Configured' : 'Pending Verification'}</span>
                </div>
              )}
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Beneficiary / Account Holder Name
                </label>
                <input
                  type="text"
                  placeholder="e.g. Sharma Wholesale Pvt Ltd"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                  value={paymentData.beneficiaryName}
                  onChange={(e) => setPaymentData({ ...paymentData, beneficiaryName: e.target.value })}
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Bank Account Number
                </label>
                {paymentAccount?.maskedAccountNumber && (
                  <p className="text-xs text-slate-500 mb-1">Current: <span className="font-mono font-bold">{paymentAccount.maskedAccountNumber}</span></p>
                )}
                <input
                  type="text"
                  placeholder={paymentAccount?.maskedAccountNumber ? 'Enter new account number to update' : 'Enter account number'}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-mono font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                  value={paymentData.accountNumber}
                  onChange={(e) => setPaymentData({ ...paymentData, accountNumber: e.target.value })}
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Bank IFSC Code
                </label>
                <input
                  type="text"
                  placeholder="HDFC0000123"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-mono font-medium uppercase focus:outline-none focus:ring-2 focus:ring-brand-500"
                  value={paymentData.ifscCode}
                  onChange={(e) => setPaymentData({ ...paymentData, ifscCode: e.target.value.toUpperCase() })}
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  UPI VPA ID (For Instant Payouts)
                </label>
                <input
                  type="text"
                  placeholder="seller@okaxis"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm text-slate-900 font-medium focus:outline-none focus:ring-2 focus:ring-brand-500"
                  value={paymentData.vpaId}
                  onChange={(e) => setPaymentData({ ...paymentData, vpaId: e.target.value })}
                />
              </div>
            </div>

            <div className="p-3 bg-slate-50 rounded-xl text-xs text-slate-500 flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-emerald-600 shrink-0" />
              <span>Banking credentials are encrypted. Payouts are routed directly via regulated payment gateway transfers with UTR verification.</span>
            </div>

            <div className="flex justify-end">
              <button
                type="button"
                onClick={handleSavePaymentAccount}
                disabled={savingPayment}
                className="flex items-center gap-2 py-2.5 px-6 rounded-xl bg-purple-600 hover:bg-purple-700 active:scale-95 text-white font-bold text-xs shadow-sm transition-all disabled:opacity-50"
              >
                {savingPayment ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    <span>Saving Account...</span>
                  </>
                ) : (
                  <>
                    <Save className="w-4 h-4" />
                    <span>Save Payment Account</span>
                  </>
                )}
              </button>
            </div>
          </div>

          {/* Sticky Bottom Save Bar */}
          <div className="sticky bottom-4 z-20 flex items-center justify-between p-4 rounded-2xl bg-white/90 backdrop-blur-md border border-slate-200/80 shadow-[0_8px_30px_rgba(0,0,0,0.08)]">
            <div className="text-xs text-slate-500">
              Changes update immediately across the Retailer marketplace app.
            </div>

            <button
              type="submit"
              disabled={saving || uploadingImage}
              className="flex items-center gap-2 py-3 px-8 rounded-xl bg-brand-500 hover:bg-brand-600 active:scale-95 text-white font-bold text-xs shadow-btn-primary transition-all disabled:opacity-50"
            >
              {saving ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  <span>Saving Profile...</span>
                </>
              ) : (
                <>
                  <Save className="w-4 h-4" />
                  <span>Save All Changes</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
