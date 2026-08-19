const Footer = () => (
  <footer className="bg-white border-t border-gray-100 py-5 mt-auto">
    <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-2 text-xs text-gray-400">
      <span>© {new Date().getFullYear()} Zone Store · All rights reserved</span>
      <span>
        Support:{' '}
        <a href="mailto:support@zonesupply.in" className="text-brand-500 hover:underline">
          support@zonesupply.in
        </a>
      </span>
    </div>
  </footer>
);

export default Footer;
