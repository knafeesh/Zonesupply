import { Link } from 'react-router-dom';
import Navbar from '../components/Navbar';
import Footer from '../components/Footer';

const steps = [
  { num: '01', label: 'Fill Application', desc: 'Complete our simple 4-step form with your business details.' },
  { num: '02', label: 'Upload Documents', desc: 'Submit KYC documents for quick verification.' },
  { num: '03', label: 'Team Review',      desc: 'We review your application within 2-3 business days.' },
  { num: '04', label: 'Get Membership',   desc: 'Receive your Zone Store Membership ID and start saving!' },
];

const LandingPage = () => (
  <div className="min-h-screen flex flex-col bg-[#F8FAFF]">
    <Navbar />

    {/* ── Hero ─────────────────────────────────────────────────── */}
    <section className="relative overflow-hidden bg-white border-b border-gray-100 flex-1 flex flex-col justify-center">
      {/* Light blue diagonal accent */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        <div className="absolute -top-32 -right-32 w-[480px] h-[480px] rounded-full bg-brand-50 opacity-80" />
        <div className="absolute top-1/2 -left-20 w-72 h-72 rounded-full bg-brand-50 opacity-60" />
      </div>

      <div className="relative max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-16 md:py-24 w-full">
        <div className="max-w-2xl">

          {/* Live badge */}
          <div className="inline-flex items-center gap-2 bg-brand-50 border border-brand-200 rounded-full px-4 py-1.5 text-xs font-semibold text-brand-700 mb-6 animate-fade-in">
            <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse-slow" />
            Membership
          </div>

          <h1 className="text-4xl md:text-5xl font-black text-gray-900 leading-tight mb-5 animate-slide-up">
            ZONESUPPLY RETAILER<br />
            <span className="text-brand-500">MEMBERSHIP</span>
          </h1>

          <p className="text-base md:text-lg text-gray-500 leading-relaxed mb-8 animate-fade-in">
            Join <strong className="text-gray-800">10,000+ verified retailers</strong> on Zone Store's exclusive
            B2B network. Wholesale pricing, priority delivery, and credit facility — all in one membership.
          </p>

          <div className="flex flex-col sm:flex-row gap-3 mb-12 animate-fade-in">
            <Link to="/apply" id="hero-apply-btn"
              className="btn-primary text-base px-8 py-3.5">
              Apply for Membership
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
              </svg>
            </Link>
            <Link to="/check-status" id="hero-status-btn"
              className="btn-secondary text-base px-8 py-3.5">
              Check My Status
            </Link>
          </div>

          {/* Stats row */}
          <div className="flex flex-wrap gap-8 animate-fade-in">
            {[
              { val: '10K+',  label: 'Active Retailers' },
              { val: '₹50Cr+', label: 'Monthly GMV' },
              { val: '28',    label: 'States Covered' },
            ].map(s => (
              <div key={s.label}>
                <div className="text-2xl font-black text-brand-600">{s.val}</div>
                <div className="text-xs text-gray-400 font-medium mt-0.5">{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>

    {/* ── How It Works ─────────────────────────────────────────── */}
    <section className="py-16 bg-[#F8FAFF] border-t border-gray-100">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-10">
          <span className="text-xs font-semibold text-brand-600 bg-brand-50 border border-brand-100 px-4 py-1.5 rounded-full uppercase tracking-wider">
            Simple Process
          </span>
          <h2 className="text-2xl md:text-3xl font-black text-gray-900 mt-4 mb-2">
            How It Works
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {steps.map((s, i) => (
            <div key={s.num} className="relative">
              <div className="bg-white rounded-2xl border border-gray-100 shadow-card p-5 text-center h-full
                              hover:shadow-card-hover hover:-translate-y-0.5 transition-all duration-200">
                <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-brand-500 to-brand-700 text-white
                                font-black text-base flex items-center justify-center mx-auto mb-4 shadow-btn">
                  {s.num}
                </div>
                <h3 className="font-bold text-gray-900 text-sm mb-1.5">{s.label}</h3>
                <p className="text-gray-400 text-xs leading-relaxed">{s.desc}</p>
              </div>
              {i < steps.length - 1 && (
                <div className="hidden lg:block absolute top-10 -right-3 text-brand-300 text-xl z-10 font-bold">
                  →
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>

    <Footer />
  </div>
);

export default LandingPage;
