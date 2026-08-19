import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import Navbar from '../components/Navbar';
import Footer from '../components/Footer';
import StepIndicator from '../components/StepIndicator';
import FileUpload from '../components/FileUpload';
import { submitApplication } from '../services/api';
import { ApplicationFormData, INDIAN_STATES, BUSINESS_TYPES } from '../types';

const STEPS = [
  { number: 1, label: 'Personal Info' },
  { number: 2, label: 'Business Details' },
  { number: 3, label: 'Documents' },
  { number: 4, label: 'Review & Submit' },
];

const INITIAL: ApplicationFormData = {
  fullName: '', mobile: '', email: '',
  shopName: '', businessType: '', gstNumber: '',
  address: '', state: '', city: '', pincode: '',
  aadhaar: null, pan: null, shopPhoto: null, gstCert: null,
  termsAccepted: false,
};

const ApplicationForm = () => {
  const navigate = useNavigate();
  const [step, setStep] = useState(1);
  const [form, setForm] = useState<ApplicationFormData>(INITIAL);
  const [errors, setErrors] = useState<Partial<Record<keyof ApplicationFormData, string>>>({});
  const [submitting, setSubmitting] = useState(false);

  const set = (field: keyof ApplicationFormData, value: any) => {
    setForm(p => ({ ...p, [field]: value }));
    setErrors(p => ({ ...p, [field]: '' }));
  };

  // ─── Validation per step ───────────────────────────────────
  const validate = (s: number): boolean => {
    const e: typeof errors = {};

    if (s === 1) {
      if (form.fullName.trim().length < 3) e.fullName = 'Name must be at least 3 characters';
      if (!/^[6-9]\d{9}$/.test(form.mobile)) e.mobile = 'Enter valid 10-digit mobile number';
      if (!/\S+@\S+\.\S+/.test(form.email)) e.email = 'Enter a valid email address';
    }

    if (s === 2) {
      if (form.shopName.trim().length < 2) e.shopName = 'Shop name required';
      if (!form.businessType) e.businessType = 'Select a business type';
      if (form.gstNumber && !/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/.test(form.gstNumber))
        e.gstNumber = 'Enter valid GST number';
      if (form.address.trim().length < 10) e.address = 'Address must be at least 10 characters';
      if (!form.state) e.state = 'Select your state';
      if (form.city.trim().length < 2) e.city = 'City name required';
      if (!/^[1-9][0-9]{5}$/.test(form.pincode)) e.pincode = 'Enter valid 6-digit pincode';
    }

    if (s === 3) {
      if (!form.aadhaar) e.aadhaar = 'Aadhaar card is required';
      if (!form.pan) e.pan = 'PAN card is required';
      if (!form.shopPhoto) e.shopPhoto = 'Shop photo is required';
    }

    if (s === 4) {
      if (!form.termsAccepted) e.termsAccepted = 'You must accept the Terms & Conditions';
    }

    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const next = () => { if (validate(step)) setStep(s => s + 1); };
  const prev = () => setStep(s => s - 1);

  const handleSubmit = async () => {
    if (!validate(4)) return;
    setSubmitting(true);
    try {
      const res = await submitApplication(form);
      if (res.success && res.data?.applicationId) {
        toast.success('Application submitted successfully!');
        navigate(`/success/${res.data.applicationId}`);
      } else {
        toast.error(res.message || 'Submission failed. Try again.');
      }
    } catch (err: any) {
      const msg = err?.response?.data?.message || 'Network error. Please try again.';
      toast.error(msg);
    } finally {
      setSubmitting(false);
    }
  };

  const inputCls = (field: keyof ApplicationFormData) =>
    `input-field ${errors[field] ? 'border-red-400 focus:ring-red-400 focus:border-red-400' : ''}`;

  return (
    <div className="min-h-screen flex flex-col bg-[#F8FAFF]">
      <Navbar />

      {/* Page Header */}
      <div className="bg-white border-b border-gray-100 py-8">
        <div className="max-w-3xl mx-auto px-4 text-center">
          <h1 className="text-2xl md:text-3xl font-black text-gray-900 mb-1">Membership Application</h1>
          <p className="text-gray-400 text-sm">Complete all 4 steps to submit your application</p>
        </div>
      </div>

      <div className="flex-1 max-w-3xl mx-auto w-full px-4 py-8">
        {/* Step Indicator */}
        <StepIndicator steps={STEPS} currentStep={step} />

        {/* Form Card */}
        <div className="card p-6 md:p-8 animate-fade-in">

          {/* ── Step 1: Personal Info ── */}
          {step === 1 && (
            <div className="space-y-5">
              <div>
                <h2 className="text-xl font-bold text-gray-900">Personal Information</h2>
                <p className="text-sm text-gray-500 mt-1">Enter your personal contact details</p>
              </div>
              <div>
                <label className="label">Full Name <span className="text-red-500">*</span></label>
                <input id="fullName" className={inputCls('fullName')} placeholder="e.g. Rahul Sharma"
                  value={form.fullName} onChange={e => set('fullName', e.target.value)} />
                {errors.fullName && <p className="error-text">{errors.fullName}</p>}
              </div>
              <div>
                <label className="label">Mobile Number <span className="text-red-500">*</span></label>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-medium text-sm">+91</span>
                  <input id="mobile" className={`${inputCls('mobile')} pl-12`} placeholder="9876543210"
                    value={form.mobile} onChange={e => set('mobile', e.target.value.replace(/\D/g, '').slice(0, 10))}
                    maxLength={10} inputMode="numeric" />
                </div>
                {errors.mobile && <p className="error-text">{errors.mobile}</p>}
              </div>
              <div>
                <label className="label">Email Address <span className="text-red-500">*</span></label>
                <input id="email" type="email" className={inputCls('email')} placeholder="rahul@example.com"
                  value={form.email} onChange={e => set('email', e.target.value)} />
                {errors.email && <p className="error-text">{errors.email}</p>}
              </div>
            </div>
          )}

          {/* ── Step 2: Business Details ── */}
          {step === 2 && (
            <div className="space-y-5">
              <div>
                <h2 className="text-xl font-bold text-gray-900">Business Details</h2>
                <p className="text-sm text-gray-500 mt-1">Tell us about your shop and location</p>
              </div>
              <div>
                <label className="label">Shop / Business Name <span className="text-red-500">*</span></label>
                <input id="shopName" className={inputCls('shopName')} placeholder="e.g. Sharma General Store"
                  value={form.shopName} onChange={e => set('shopName', e.target.value)} />
                {errors.shopName && <p className="error-text">{errors.shopName}</p>}
              </div>
              <div>
                <label className="label">Business Type <span className="text-red-500">*</span></label>
                <select id="businessType" className={inputCls('businessType')}
                  value={form.businessType} onChange={e => set('businessType', e.target.value)}>
                  <option value="">Select business type...</option>
                  {BUSINESS_TYPES.map(b => <option key={b.value} value={b.value}>{b.label}</option>)}
                </select>
                {errors.businessType && <p className="error-text">{errors.businessType}</p>}
              </div>
              <div>
                <label className="label">GST Number <span className="text-gray-400 font-normal">(Optional)</span></label>
                <input id="gstNumber" className={inputCls('gstNumber')} placeholder="e.g. 29ABCDE1234F1Z5"
                  value={form.gstNumber} onChange={e => set('gstNumber', e.target.value.toUpperCase())}
                  maxLength={15} />
                {errors.gstNumber && <p className="error-text">{errors.gstNumber}</p>}
              </div>
              <div>
                <label className="label">Full Address <span className="text-red-500">*</span></label>
                <textarea id="address" className={`${inputCls('address')} resize-none`} rows={3}
                  placeholder="Shop no, Street, Area, Landmark..."
                  value={form.address} onChange={e => set('address', e.target.value)} />
                {errors.address && <p className="error-text">{errors.address}</p>}
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="sm:col-span-1">
                  <label className="label">State <span className="text-red-500">*</span></label>
                  <select id="state" className={inputCls('state')}
                    value={form.state} onChange={e => set('state', e.target.value)}>
                    <option value="">Select state...</option>
                    {INDIAN_STATES.map(s => <option key={s} value={s}>{s}</option>)}
                  </select>
                  {errors.state && <p className="error-text">{errors.state}</p>}
                </div>
                <div>
                  <label className="label">City <span className="text-red-500">*</span></label>
                  <input id="city" className={inputCls('city')} placeholder="e.g. Mumbai"
                    value={form.city} onChange={e => set('city', e.target.value)} />
                  {errors.city && <p className="error-text">{errors.city}</p>}
                </div>
                <div>
                  <label className="label">Pincode <span className="text-red-500">*</span></label>
                  <input id="pincode" className={inputCls('pincode')} placeholder="400001"
                    value={form.pincode} onChange={e => set('pincode', e.target.value.replace(/\D/g, '').slice(0, 6))}
                    maxLength={6} inputMode="numeric" />
                  {errors.pincode && <p className="error-text">{errors.pincode}</p>}
                </div>
              </div>
            </div>
          )}

          {/* ── Step 3: Documents ── */}
          {step === 3 && (
            <div className="space-y-5">
              <div>
                <h2 className="text-xl font-bold text-gray-900">Upload Documents</h2>
                <p className="text-sm text-gray-500 mt-1">All documents must be clear and legible. Max 5MB each.</p>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                <div>
                  <FileUpload id="aadhaar" label="Aadhaar Card" required value={form.aadhaar}
                    onChange={f => set('aadhaar', f)} hint="Front side of Aadhaar — JPG/PNG/PDF" />
                  {errors.aadhaar && <p className="error-text">{errors.aadhaar}</p>}
                </div>
                <div>
                  <FileUpload id="pan" label="PAN Card" required value={form.pan}
                    onChange={f => set('pan', f)} hint="Clear photo of PAN card — JPG/PNG/PDF" />
                  {errors.pan && <p className="error-text">{errors.pan}</p>}
                </div>
                <div>
                  <FileUpload id="shopPhoto" label="Shop / Store Photo" required value={form.shopPhoto}
                    onChange={f => set('shopPhoto', f)} hint="Recent photo of your shop exterior" />
                  {errors.shopPhoto && <p className="error-text">{errors.shopPhoto}</p>}
                </div>
                <div>
                  <FileUpload id="gstCert" label="GST Certificate" value={form.gstCert}
                    onChange={f => set('gstCert', f)} hint="Optional — if GST registered" />
                </div>
              </div>
              <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 text-sm text-amber-700">
                <strong>📋 Note:</strong> All uploaded documents are securely stored and used only for membership verification. 
                We do not share your information with third parties.
              </div>
            </div>
          )}

          {/* ── Step 4: Review & Submit ── */}
          {step === 4 && (
            <div className="space-y-6">
              <div>
                <h2 className="text-xl font-bold text-gray-900">Review Your Application</h2>
                <p className="text-sm text-gray-500 mt-1">Please verify all details before submitting</p>
              </div>

              {/* Review Sections */}
              <div className="space-y-4">
                <ReviewSection title="Personal Information" onEdit={() => setStep(1)}>
                  <ReviewRow label="Full Name" value={form.fullName} />
                  <ReviewRow label="Mobile" value={`+91 ${form.mobile}`} />
                  <ReviewRow label="Email" value={form.email} />
                </ReviewSection>

                <ReviewSection title="Business Details" onEdit={() => setStep(2)}>
                  <ReviewRow label="Shop Name" value={form.shopName} />
                  <ReviewRow label="Business Type" value={BUSINESS_TYPES.find(b => b.value === form.businessType)?.label || form.businessType} />
                  {form.gstNumber && <ReviewRow label="GST Number" value={form.gstNumber} />}
                  <ReviewRow label="Address" value={form.address} />
                  <ReviewRow label="Location" value={`${form.city}, ${form.state} - ${form.pincode}`} />
                </ReviewSection>

                <ReviewSection title="Documents" onEdit={() => setStep(3)}>
                  <ReviewRow label="Aadhaar" value={form.aadhaar?.name || '—'} />
                  <ReviewRow label="PAN" value={form.pan?.name || '—'} />
                  <ReviewRow label="Shop Photo" value={form.shopPhoto?.name || '—'} />
                  {form.gstCert && <ReviewRow label="GST Certificate" value={form.gstCert.name} />}
                </ReviewSection>
              </div>

              {/* Terms */}
              <div className={`rounded-xl border-2 p-4 ${errors.termsAccepted ? 'border-red-300 bg-red-50' : 'border-gray-200 bg-gray-50'}`}>
                <label className="flex items-start gap-3 cursor-pointer">
                  <input id="termsAccepted" type="checkbox"
                    className="mt-0.5 w-4 h-4 text-brand-600 border-gray-300 rounded focus:ring-brand-500"
                    checked={form.termsAccepted}
                    onChange={e => set('termsAccepted', e.target.checked)} />
                  <span className="text-sm text-gray-700 leading-relaxed">
                    I confirm that all information provided is accurate and complete. I agree to Zone Store's{' '}
                    <a href="#" className="text-brand-600 font-semibold hover:underline">Terms & Conditions</a>
                    {' '}and{' '}
                    <a href="#" className="text-brand-600 font-semibold hover:underline">Privacy Policy</a>.
                    I understand that providing false information may result in permanent rejection.
                  </span>
                </label>
                {errors.termsAccepted && <p className="error-text mt-2">{errors.termsAccepted}</p>}
              </div>
            </div>
          )}

          {/* Navigation Buttons */}
          <div className={`flex gap-3 mt-8 ${step === 1 ? 'justify-end' : 'justify-between'}`}>
            {step > 1 && (
              <button type="button" onClick={prev} className="btn-secondary">
                ← Previous
              </button>
            )}
            {step < 4 ? (
              <button type="button" id={`step-${step}-next`} onClick={next} className="btn-primary">
                Next Step →
              </button>
            ) : (
              <button type="button" id="submit-application" onClick={handleSubmit}
                disabled={submitting} className="btn-primary min-w-[180px]">
                {submitting ? (
                  <>
                    <svg className="w-4 h-4 spinner" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                    </svg>
                    Submitting...
                  </>
                ) : '🚀 Submit Application'}
              </button>
            )}
          </div>
        </div>
      </div>
      <Footer />
    </div>
  );
};

// Review helpers
const ReviewSection = ({ title, children, onEdit }: { title: string; children: React.ReactNode; onEdit: () => void }) => (
  <div className="border border-gray-200 rounded-xl overflow-hidden">
    <div className="flex items-center justify-between px-4 py-3 bg-brand-50 border-b border-gray-200">
      <h3 className="font-semibold text-brand-800 text-sm">{title}</h3>
      <button onClick={onEdit} className="text-xs text-brand-600 font-semibold hover:underline">Edit</button>
    </div>
    <div className="px-4 py-3 space-y-2">{children}</div>
  </div>
);

const ReviewRow = ({ label, value }: { label: string; value: string }) => (
  <div className="flex gap-3 text-sm">
    <span className="text-gray-500 min-w-[120px] flex-shrink-0">{label}:</span>
    <span className="text-gray-900 font-medium break-all">{value}</span>
  </div>
);

export default ApplicationForm;
