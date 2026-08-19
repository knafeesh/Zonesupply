import { Link, useLocation } from 'react-router-dom';

const Navbar = () => {
  const location = useLocation();
  const isApplyPage = location.pathname === '/apply';

  const navLink = (to: string, label: string) => (
    <Link
      to={to}
      className={`px-4 py-2 rounded-lg text-sm font-medium transition-all duration-150 ${
        location.pathname === to
          ? 'text-brand-600 bg-brand-50 font-semibold'
          : 'text-gray-600 hover:text-brand-600 hover:bg-brand-50/60'
      }`}
    >
      {label}
    </Link>
  );

  return (
    <header className="sticky top-0 z-50 bg-white border-b border-gray-100 shadow-sm">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-14">

          {/* Logo — matches retailer app header style */}
          <Link to="/" className="flex items-center gap-2.5 group">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-brand-500 to-brand-700 flex items-center justify-center shadow-sm group-hover:scale-105 transition-transform duration-200">
              <span className="text-white font-black text-xs">ZS</span>
            </div>
            <div className="leading-none">
              <div className="font-bold text-gray-900 text-sm">Zone Store</div>
              <div className="text-[11px] text-brand-500 font-medium mt-0.5">Membership Portal</div>
            </div>
          </Link>

          {/* Nav Links */}
          <nav className="hidden sm:flex items-center gap-0.5">
            {navLink('/', 'Home')}
            {navLink('/check-status', 'Check Status')}
          </nav>

          {/* CTA */}
          {!isApplyPage ? (
            <Link to="/apply" id="nav-apply-btn" className="btn-primary text-sm px-4 py-2">
              Apply Now
            </Link>
          ) : (
            <Link to="/" className="btn-secondary text-sm px-4 py-2">
              ← Back
            </Link>
          )}
        </div>
      </div>
    </header>
  );
};

export default Navbar;
