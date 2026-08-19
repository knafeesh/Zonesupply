import React, { useState, useEffect, useRef } from 'react';
import { useOutletContext } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { EmptyState } from '../../components/common/EmptyState';
import { ConfirmDialog } from '../../components/common/ConfirmDialog';
import { Modal } from '../../components/common/Modal';
import { bannerService, CreateBannerDto } from '../../services/bannerService';
import { Banner } from '../../types';
import { ALL_CATEGORY_NAMES } from '../../constants/categories';
import {
  Plus,
  Search,
  Sparkles,
  Edit2,
  Trash2,
  Image as ImageIcon,
  CheckCircle2,
  Power,
  Upload,
  Layers,
  ShoppingBag,
  TrendingUp,
  Tag,
  Palette,
  ExternalLink,
  Eye,
} from 'lucide-react';
import toast from 'react-hot-toast';

const GRADIENT_PRESETS = [
  { name: 'Purple Luxury', start: '#6C3BD5', end: '#BB4DE0' },
  { name: 'Rose Berry', start: '#D4367C', end: '#FF8A65' },
  { name: 'Royal Ocean', start: '#1565C0', end: '#00ACC1' },
  { name: 'Emerald Forest', start: '#2E7D32', end: '#66BB6A' },
  { name: 'Sunset Amber', start: '#E65100', end: '#FFB300' },
  { name: 'Midnight Indigo', start: '#1E293B', end: '#475569' },
  { name: 'Deep Crimson', start: '#991B1B', end: '#EF4444' },
  { name: 'Teal Lagoon', start: '#00695C', end: '#4DB6AC' },
];

const FASHION_SUBCATEGORIES = [
  'All Fashion',
  "Men's Wear",
  "Women's Wear",
  'Ethnic Wear',
  'Kids Wear',
  'Footwear',
  'Accessories',
  'Sportswear',
  'Innerwear',
  'Winter Wear',
];

const SAMPLE_IMAGE_PRESETS = [
  {
    name: 'Ethnic Sarees',
    url: 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=800&auto=format&fit=crop&q=80',
  },
  {
    name: 'Men Shirts & Tees',
    url: 'https://images.unsplash.com/photo-1490114538077-0a7f8cb49891?w=800&auto=format&fit=crop&q=80',
  },
  {
    name: 'Fashion Retail Rack',
    url: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&auto=format&fit=crop&q=80',
  },
  {
    name: 'Kids Apparel',
    url: 'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=800&auto=format&fit=crop&q=80',
  },
  {
    name: 'Sneakers & Shoes',
    url: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800&auto=format&fit=crop&q=80',
  },
];

export const Banners: React.FC = () => {
  const { onOpenSidebar } = useOutletContext<{ onOpenSidebar: () => void }>();

  const [banners, setBanners] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('ALL');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'PAUSED'>('ALL');

  // Modal State
  const [modalOpen, setModalOpen] = useState(false);
  const [editingBanner, setEditingBanner] = useState<Banner | null>(null);
  const [deletingBanner, setDeletingBanner] = useState<Banner | null>(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [uploadingImage, setUploadingImage] = useState(false);

  // Form State
  const [title, setTitle] = useState('');
  const [subtitle, setSubtitle] = useState('');
  const [tag, setTag] = useState('TRENDING NOW');
  const [imageUrl, setImageUrl] = useState('');
  const [category, setCategory] = useState('Fashion');
  const [subCategory, setSubCategory] = useState('');
  const [gradientStart, setGradientStart] = useState('#6C3BD5');
  const [gradientEnd, setGradientEnd] = useState('#BB4DE0');
  const [isActive, setIsActive] = useState(true);
  const [displayOrder, setDisplayOrder] = useState(0);

  const fileInputRef = useRef<HTMLInputElement>(null);

  const fetchBanners = async () => {
    try {
      const data = await bannerService.getMyBanners();
      setBanners(data);
    } catch {
      toast.error('Failed to load banners');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBanners();
  }, []);

  const openCreateModal = () => {
    setEditingBanner(null);
    setTitle('');
    setSubtitle('');
    setTag('TRENDING NOW');
    setImageUrl(SAMPLE_IMAGE_PRESETS[0].url);
    setCategory('Fashion');
    setSubCategory('All Fashion');
    setGradientStart('#6C3BD5');
    setGradientEnd('#BB4DE0');
    setIsActive(true);
    setDisplayOrder(0);
    setModalOpen(true);
  };

  const openEditModal = (b: Banner) => {
    setEditingBanner(b);
    setTitle(b.title);
    setSubtitle(b.subtitle || '');
    setTag(b.tag || 'OFFER');
    setImageUrl(b.imageUrl);
    setCategory(b.category || 'Fashion');
    setSubCategory(b.subCategory || '');
    setGradientStart(b.gradientStart || '#6C3BD5');
    setGradientEnd(b.gradientEnd || '#BB4DE0');
    setIsActive(b.isActive);
    setDisplayOrder(b.displayOrder || 0);
    setModalOpen(true);
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadingImage(true);
    try {
      const res = await bannerService.uploadImage(file);
      setImageUrl(res.url);
      toast.success('Banner image uploaded successfully');
    } catch {
      toast.error('Failed to upload image. Please try a different file.');
    } finally {
      setUploadingImage(false);
    }
  };

  const handleSaveBanner = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) {
      toast.error('Please enter a banner title');
      return;
    }
    if (!imageUrl.trim()) {
      toast.error('Please provide an image for the banner');
      return;
    }

    setActionLoading(true);
    const dto: CreateBannerDto = {
      title: title.trim(),
      subtitle: subtitle.trim() || undefined,
      tag: tag.trim() || 'OFFER',
      imageUrl: imageUrl.trim(),
      category,
      subCategory: subCategory.trim() || undefined,
      gradientStart,
      gradientEnd,
      isActive,
      displayOrder: Number(displayOrder) || 0,
    };

    try {
      if (editingBanner) {
        await bannerService.updateBanner(editingBanner.id, dto);
        toast.success('Offer banner updated successfully');
      } else {
        await bannerService.createBanner(dto);
        toast.success('Offer banner published to Retailer App!');
      }
      setModalOpen(false);
      fetchBanners();
    } catch {
      toast.error(editingBanner ? 'Failed to update banner' : 'Failed to create banner');
    } finally {
      setActionLoading(false);
    }
  };

  const handleToggleActive = async (b: Banner) => {
    try {
      await bannerService.toggleBanner(b.id);
      toast.success(`Banner ${b.isActive ? 'paused' : 'activated'}`);
      fetchBanners();
    } catch {
      toast.error('Failed to toggle banner status');
    }
  };

  const handleDelete = async () => {
    if (!deletingBanner) return;
    setActionLoading(true);
    try {
      await bannerService.deleteBanner(deletingBanner.id);
      toast.success('Banner deleted successfully');
      setDeletingBanner(null);
      fetchBanners();
    } catch {
      toast.error('Failed to delete banner');
    } finally {
      setActionLoading(false);
    }
  };

  // Metrics
  const totalCount = banners.length;
  const activeCount = banners.filter((b) => b.isActive).length;
  const fashionCount = banners.filter((b) => (b.category || '').toLowerCase() === 'fashion').length;
  const pausedCount = totalCount - activeCount;

  // Filtered List
  const filteredBanners = banners.filter((b) => {
    const matchesSearch =
      b.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (b.subtitle && b.subtitle.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (b.tag && b.tag.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (b.category && b.category.toLowerCase().includes(searchQuery.toLowerCase()));

    const matchesCategory =
      selectedCategory === 'ALL' ||
      (b.category && b.category.toLowerCase() === selectedCategory.toLowerCase());

    const matchesStatus =
      statusFilter === 'ALL' ||
      (statusFilter === 'ACTIVE' && b.isActive) ||
      (statusFilter === 'PAUSED' && !b.isActive);

    return matchesSearch && matchesCategory && matchesStatus;
  });

  const categories = [
    'ALL',
    'Fashion',
    ...ALL_CATEGORY_NAMES.filter((c) => c !== 'Fashion'),
  ];

  return (
    <div className="flex flex-col min-h-screen bg-slate-50/60 pb-16">
      <Header
        onOpenSidebar={onOpenSidebar}
        title="Offer Slideshow & Banners"
        subtitle="Manage and publish wholesale offer slideshows, seasonal discounts & fashion highlights in real-time"
      />

      <div className="px-4 sm:px-6 lg:px-8 py-6 space-y-6 max-w-7xl w-full mx-auto">
        {/* Top Metric Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-purple-50 flex items-center justify-center text-purple-600">
              <Sparkles className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Total Banners</p>
              <p className="text-2xl font-bold text-slate-900 mt-0.5">{totalCount}</p>
            </div>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-600">
              <CheckCircle2 className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Active In App</p>
              <p className="text-2xl font-bold text-emerald-600 mt-0.5">{activeCount}</p>
            </div>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-pink-50 flex items-center justify-center text-pink-600">
              <ShoppingBag className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Fashion Hub Offers</p>
              <p className="text-2xl font-bold text-pink-600 mt-0.5">{fashionCount}</p>
            </div>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-amber-50 flex items-center justify-center text-amber-600">
              <Power className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Paused / Draft</p>
              <p className="text-2xl font-bold text-amber-600 mt-0.5">{pausedCount}</p>
            </div>
          </div>
        </div>

        {/* Action Header & Filters */}
        <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 flex-1">
            {/* Search Input */}
            <div className="relative flex-1 max-w-md">
              <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search banners by title, tag, or subcategory..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 transition-all"
              />
            </div>

            {/* Status Filter */}
            <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl">
              {(['ALL', 'ACTIVE', 'PAUSED'] as const).map((st) => (
                <button
                  key={st}
                  onClick={() => setStatusFilter(st)}
                  className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all ${
                    statusFilter === st
                      ? 'bg-white text-slate-900 shadow-sm'
                      : 'text-slate-500 hover:text-slate-900'
                  }`}
                >
                  {st === 'ALL' ? 'All' : st === 'ACTIVE' ? 'Active' : 'Paused'}
                </button>
              ))}
            </div>
          </div>

          <button
            onClick={openCreateModal}
            className="flex items-center justify-center gap-2 px-5 py-2.5 bg-brand-500 hover:bg-brand-600 text-white font-semibold text-xs rounded-xl shadow-btn-primary transition-all duration-150 active:scale-[0.98]"
          >
            <Plus className="w-4 h-4" />
            <span>New Offer Banner</span>
          </button>
        </div>

        {/* Category Filter Chips */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 custom-scrollbar">
          {categories.slice(0, 10).map((cat) => {
            const isSel = selectedCategory === cat;
            return (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`px-3.5 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition-all ${
                  isSel
                    ? 'bg-brand-500 text-white shadow-sm'
                    : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'
                }`}
              >
                {cat === 'ALL' ? 'All Categories' : cat}
              </button>
            );
          })}
        </div>

        {/* Content Body */}
        {loading ? (
          <div className="py-20 flex justify-center">
            <LoadingSpinner message="Loading offer banners..." />
          </div>
        ) : filteredBanners.length === 0 ? (
          <EmptyState
            title="No offer banners found"
            description="Create your first offer banner to highlight your wholesale products on the Retailer mobile app slideshow!"
            actionText="Create Banner Now"
            onAction={openCreateModal}
          />
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredBanners.map((b) => {
              const bgGradient = `linear-gradient(135deg, ${b.gradientStart || '#6C3BD5'}, ${b.gradientEnd || '#BB4DE0'})`;
              return (
                <div
                  key={b.id}
                  className="group relative bg-white rounded-2xl border border-slate-200/80 shadow-sm hover:shadow-md transition-all duration-200 flex flex-col overflow-hidden"
                >
                  {/* Banner Mobile Slideshow Preview Card */}
                  <div
                    className="relative h-48 w-full p-5 flex flex-col justify-end text-white overflow-hidden"
                    style={{ background: bgGradient }}
                  >
                    {/* Background photo overlay */}
                    {b.imageUrl && (
                      <img
                        src={b.imageUrl}
                        alt={b.title}
                        className="absolute inset-0 w-full h-full object-cover mix-blend-overlay opacity-50 group-hover:scale-105 transition-transform duration-500"
                        onError={(e) => {
                          (e.target as HTMLElement).style.display = 'none';
                        }}
                      />
                    )}

                    {/* Top Status & Category Badges */}
                    <div className="absolute top-3 left-3 right-3 flex items-center justify-between z-10">
                      <span className="px-2.5 py-1 rounded-full text-[10px] font-extrabold uppercase tracking-wider bg-white/20 backdrop-blur-md border border-white/30 text-white">
                        {b.category || 'Fashion'}
                      </span>

                      <button
                        onClick={() => handleToggleActive(b)}
                        className={`px-2.5 py-1 rounded-full text-[10px] font-bold flex items-center gap-1.5 transition-all ${
                          b.isActive
                            ? 'bg-emerald-500 text-white shadow-sm'
                            : 'bg-slate-800/80 text-slate-300 backdrop-blur-md'
                        }`}
                      >
                        <span className={`w-1.5 h-1.5 rounded-full ${b.isActive ? 'bg-white animate-pulse' : 'bg-slate-400'}`} />
                        {b.isActive ? 'LIVE IN APP' : 'PAUSED'}
                      </button>
                    </div>

                    {/* Banner Content */}
                    <div className="relative z-10 space-y-1">
                      <span className="inline-block px-2 py-0.5 rounded-md text-[9px] font-black tracking-widest uppercase bg-white/30 backdrop-blur-sm border border-white/40">
                        {b.tag || 'OFFER'}
                      </span>
                      <h3 className="font-extrabold text-base leading-snug line-clamp-1 drop-shadow-sm">
                        {b.title}
                      </h3>
                      {b.subtitle && (
                        <p className="text-xs text-white/90 line-clamp-1 font-medium drop-shadow-sm">
                          {b.subtitle}
                        </p>
                      )}
                    </div>
                  </div>

                  {/* Banner Details & Action Footer */}
                  <div className="p-4 bg-white flex-1 flex flex-col justify-between space-y-3">
                    <div className="space-y-1.5 text-xs text-slate-600">
                      {b.subCategory && (
                        <div className="flex items-center gap-1.5">
                          <Tag className="w-3.5 h-3.5 text-slate-400" />
                          <span className="text-slate-500">Subcategory:</span>
                          <span className="font-semibold text-slate-800">{b.subCategory}</span>
                        </div>
                      )}
                      <div className="flex items-center gap-1.5">
                        <Layers className="w-3.5 h-3.5 text-slate-400" />
                        <span className="text-slate-500">Slideshow Order:</span>
                        <span className="font-semibold text-slate-800">#{b.displayOrder}</span>
                      </div>
                    </div>

                    {/* Action Buttons */}
                    <div className="pt-3 border-t border-slate-100 flex items-center justify-between gap-2">
                      <button
                        onClick={() => handleToggleActive(b)}
                        className={`flex-1 py-1.5 px-3 rounded-lg text-xs font-semibold flex items-center justify-center gap-1.5 transition-all ${
                          b.isActive
                            ? 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                            : 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200'
                        }`}
                      >
                        <Power className="w-3.5 h-3.5" />
                        {b.isActive ? 'Pause' : 'Activate'}
                      </button>

                      <button
                        onClick={() => openEditModal(b)}
                        className="p-2 rounded-lg text-slate-600 hover:text-brand-600 hover:bg-brand-50 border border-slate-200 transition-all"
                        title="Edit Banner"
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>

                      <button
                        onClick={() => setDeletingBanner(b)}
                        className="p-2 rounded-lg text-slate-600 hover:text-red-600 hover:bg-red-50 border border-slate-200 transition-all"
                        title="Delete Banner"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* CREATE / EDIT MODAL */}
      <Modal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editingBanner ? 'Edit Offer Banner' : 'Create Wholesale Offer Banner'}
        maxWidth="2xl"
      >
        <form onSubmit={handleSaveBanner} className="space-y-6">
          {/* Live Mobile Slideshow Preview Box */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-2 flex items-center gap-1.5">
              <Eye className="w-3.5 h-3.5 text-purple-600" />
              Live Retailer App Slideshow Preview
            </label>
            <div
              className="relative h-44 w-full rounded-2xl p-5 flex flex-col justify-end text-white overflow-hidden shadow-lg border border-white/20"
              style={{
                background: `linear-gradient(135deg, ${gradientStart}, ${gradientEnd})`,
              }}
            >
              {imageUrl && (
                <img
                  src={imageUrl}
                  alt="Preview"
                  className="absolute inset-0 w-full h-full object-cover mix-blend-overlay opacity-50"
                  onError={(e) => {
                    (e.target as HTMLElement).style.display = 'none';
                  }}
                />
              )}

              <div className="absolute top-3 left-3 right-3 flex items-center justify-between z-10">
                <span className="px-2.5 py-0.5 rounded-full text-[9px] font-black uppercase tracking-wider bg-white/25 backdrop-blur-md border border-white/30 text-white">
                  {category}
                </span>
                <span className="px-2.5 py-0.5 rounded-full text-[9px] font-bold bg-white/20 backdrop-blur-md text-white">
                  {isActive ? '● ACTIVE' : '○ DRAFT'}
                </span>
              </div>

              <div className="relative z-10 space-y-1">
                <span className="inline-block px-2 py-0.5 rounded-md text-[8.5px] font-black tracking-widest uppercase bg-white/30 backdrop-blur-sm border border-white/40">
                  {tag || 'OFFER'}
                </span>
                <h3 className="font-extrabold text-base leading-tight drop-shadow-sm">
                  {title || 'Your Offer Title Here'}
                </h3>
                <p className="text-xs text-white/90 font-medium line-clamp-1 drop-shadow-sm">
                  {subtitle || 'Your offer subtitle or discount highlight...'}
                </p>
              </div>
            </div>
          </div>

          {/* Offer Title & Subtitle */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Banner Headline / Title <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                placeholder="e.g. 50% Off Summer Cotton Sarees"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
                className="w-full px-3.5 py-2.5 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Offer Tag / Badge
              </label>
              <input
                type="text"
                placeholder="e.g. TRENDING NOW, BULK SPECIAL, 60% OFF"
                value={tag}
                onChange={(e) => setTag(e.target.value)}
                className="w-full px-3.5 py-2.5 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500"
              />
            </div>

            <div className="md:col-span-2">
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Subtitle / Description
              </label>
              <input
                type="text"
                placeholder="e.g. Direct manufacturer prices — Minimum order 12 pcs"
                value={subtitle}
                onChange={(e) => setSubtitle(e.target.value)}
                className="w-full px-3.5 py-2.5 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500"
              />
            </div>
          </div>

          {/* Category & Subcategory Selection */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Target Category
              </label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="w-full px-3.5 py-2.5 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500"
              >
                <option value="Fashion">Fashion (Recommended for Fashion Hub)</option>
                {ALL_CATEGORY_NAMES.filter((c) => c !== 'Fashion').map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Fashion Subcategory
              </label>
              <select
                value={subCategory}
                onChange={(e) => setSubCategory(e.target.value)}
                className="w-full px-3.5 py-2.5 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500"
              >
                {FASHION_SUBCATEGORIES.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Image Upload & Presets */}
          <div className="space-y-2">
            <label className="block text-xs font-semibold text-slate-700">
              Banner Image / Photo <span className="text-red-500">*</span>
            </label>
            <div className="flex gap-2">
              <input
                type="text"
                placeholder="Image URL or upload a photo below"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                className="flex-1 px-3.5 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500"
              />
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                disabled={uploadingImage}
                className="flex items-center gap-1.5 px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold rounded-xl border border-slate-200 transition-all"
              >
                {uploadingImage ? (
                  <span className="text-xs">Uploading...</span>
                ) : (
                  <>
                    <Upload className="w-3.5 h-3.5" />
                    <span>Upload</span>
                  </>
                )}
              </button>
              <input
                type="file"
                ref={fileInputRef}
                onChange={handleFileUpload}
                accept="image/*"
                className="hidden"
              />
            </div>

            {/* Quick Presets */}
            <div className="flex items-center gap-2 pt-1">
              <span className="text-[11px] text-slate-500">Quick Samples:</span>
              <div className="flex flex-wrap gap-1.5">
                {SAMPLE_IMAGE_PRESETS.map((p) => (
                  <button
                    key={p.name}
                    type="button"
                    onClick={() => setImageUrl(p.url)}
                    className="px-2 py-1 text-[10px] font-medium bg-slate-100 hover:bg-purple-50 hover:text-purple-700 rounded-md text-slate-600 transition-all"
                  >
                    {p.name}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Color & Theme Presets */}
          <div className="space-y-2">
            <label className="block text-xs font-semibold text-slate-700 flex items-center gap-1.5">
              <Palette className="w-3.5 h-3.5 text-slate-400" />
              Theme Gradient Colors
            </label>
            <div className="grid grid-cols-4 sm:grid-cols-8 gap-2">
              {GRADIENT_PRESETS.map((g) => {
                const isSelected = gradientStart === g.start && gradientEnd === g.end;
                return (
                  <button
                    key={g.name}
                    type="button"
                    onClick={() => {
                      setGradientStart(g.start);
                      setGradientEnd(g.end);
                    }}
                    className={`h-9 rounded-xl transition-all relative overflow-hidden flex items-center justify-center ${
                      isSelected ? 'ring-2 ring-brand-500 ring-offset-2 scale-105' : 'hover:opacity-90'
                    }`}
                    style={{
                      background: `linear-gradient(135deg, ${g.start}, ${g.end})`,
                    }}
                    title={g.name}
                  >
                    {isSelected && <CheckCircle2 className="w-4 h-4 text-white drop-shadow" />}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Active Switch & Slideshow Order */}
          <div className="flex items-center justify-between p-4 bg-slate-50 rounded-xl border border-slate-200">
            <div>
              <p className="text-xs font-bold text-slate-900">Publish to Mobile Slideshow</p>
              <p className="text-[11px] text-slate-500">
                Immediately display this banner to all retailers in the app
              </p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={isActive}
                onChange={(e) => setIsActive(e.target.checked)}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-500"></div>
            </label>
          </div>

          {/* Form Submit Footer */}
          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-xl transition-all"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={actionLoading}
              className="flex items-center gap-2 px-5 py-2 bg-brand-500 hover:bg-brand-600 text-white font-semibold text-xs rounded-xl shadow-btn-primary transition-all disabled:opacity-50"
            >
              <span>{actionLoading ? 'Saving...' : (editingBanner ? 'Save Changes' : 'Publish Offer Banner')}</span>
            </button>
          </div>
        </form>
      </Modal>

      {/* DELETE CONFIRMATION DIALOG */}
      <ConfirmDialog
        isOpen={!!deletingBanner}
        onClose={() => setDeletingBanner(null)}
        onConfirm={handleDelete}
        title="Delete Offer Banner"
        message={`Are you sure you want to delete "${deletingBanner?.title}"? It will be removed from the Retailer Mobile App slideshow.`}
        confirmText="Delete Banner"
        isLoading={actionLoading}
        isDangerous
      />
    </div>
  );
};
