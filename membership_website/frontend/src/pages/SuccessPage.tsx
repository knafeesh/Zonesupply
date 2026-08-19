import { useParams, Link } from 'react-router-dom';
import Navbar from '../components/Navbar';
import Footer from '../components/Footer';

const SuccessPage = () => {
  const { appId } = useParams<{ appId: string }>();

  return (
    <div className="min-h-screen flex flex-col bg-[#F8FAFF]">
      <Navbar />

      <div className="flex-1 flex items-center justify-center py-12 px-4">
        <div className="max-w-md w-full space-y-4">

          {/* Success Card */}
          <div className="card p-8 text-center animate-bounce-in">
            {/* Check icon */}
            <div className="w-20 h-20 rounded-full bg-green-100 flex items-center justify-center mx-auto mb-5">
              <svg className="w-10 h-10 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
              </svg>
            </div>

            <h1 className="text-2xl font-black text-gray-900 mb-2">Application Submitted!</h1>
            <p className="text-gray-400 text-sm mb-7 leading-relaxed">
              Thank you for applying to Zone Store. Your application is under review.
            </p>

            {/* Application ID */}
            <div className="bg-brand-50 border-2 border-brand-200 rounded-2xl p-5 mb-6">
              <p className="text-[10px] font-semibold text-gray-400 uppercase tracking-widest mb-2">
                Your Application ID
              </p>
              <div className="text-2xl font-black text-brand-600 tracking-widest mb-3" id="application-id">
                {appId}
              </div>
              <button
                onClick={() => { navigator.clipboard.writeText(appId || ''); }}
                className="text-xs text-brand-500 font-semibold hover:underline flex items-center gap-1 mx-auto"
              >
                📋 Copy to clipboard
              </button>
            </div>

            {/* Pending badge */}
            <div className="flex items-center justify-center gap-2 mb-6">
              <span className="w-2 h-2 bg-amber-400 rounded-full animate-pulse-slow" />
              <span className="badge-pending">Status: Pending Verification</span>
            </div>

            {/* What's next */}
            <div className="bg-gray-50 rounded-xl p-4 text-left mb-7">
              <p className="text-xs font-bold text-gray-700 mb-3">What happens next?</p>
              <ul className="space-y-2">
                {[
                  'Our team reviews your documents within 2–3 business days',
                  'You\'ll receive an SMS & email notification on approval',
                  'Your Zone Store Membership ID (ZS-XXXXXX) will be assigned',
                ].map((item, i) => (
                  <li key={i} className="flex items-start gap-2 text-xs text-gray-500">
                    <span className="text-brand-500 font-bold shrink-0 mt-0.5">✓</span>
                    {item}
                  </li>
                ))}
              </ul>
            </div>

            {/* Actions */}
            <div className="flex flex-col sm:flex-row gap-3">
              <Link to="/check-status" id="check-status-btn" className="btn-primary flex-1 text-sm">
                Track Application
              </Link>
              <Link to="/" id="back-home-btn" className="btn-secondary flex-1 text-sm">
                Back to Home
              </Link>
            </div>
          </div>

          <p className="text-center text-xs text-gray-400">
            📌 Save your ID: <strong className="text-gray-600">{appId}</strong>
          </p>
        </div>
      </div>

      <Footer />
    </div>
  );
};

export default SuccessPage;
