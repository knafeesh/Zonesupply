/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Retailer app primary palette
        brand: {
          50:  '#ebf4fe',
          100: '#d0e8fd',
          200: '#a1d1fb',
          300: '#72baf9',
          400: '#43a3f7',
          500: '#258cfb',
          600: '#0071dc',
          700: '#0057ad',
          800: '#003d7e',
          900: '#0f172a',
          950: '#080d1a',
        },
      },
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui'],
      },
      animation: {
        'fade-in':   'fadeIn 0.5s ease-out',
        'slide-up':  'slideUp 0.4s ease-out',
        'pulse-slow':'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'bounce-in': 'bounceIn 0.6s cubic-bezier(0.34, 1.56, 0.64, 1)',
      },
      keyframes: {
        fadeIn:   { '0%': { opacity: '0', transform: 'translateY(8px)' }, '100%': { opacity: '1', transform: 'translateY(0)' } },
        slideUp:  { '0%': { opacity: '0', transform: 'translateY(16px)' }, '100%': { opacity: '1', transform: 'translateY(0)' } },
        bounceIn: { '0%': { opacity: '0', transform: 'scale(0.85)' }, '100%': { opacity: '1', transform: 'scale(1)' } },
      },
      boxShadow: {
        'card':       '0 2px 16px rgba(37, 140, 251, 0.08)',
        'card-hover': '0 6px 32px rgba(37, 140, 251, 0.18)',
        'btn':        '0 4px 14px rgba(37, 140, 251, 0.35)',
        'blue':       '0 8px 24px rgba(0, 113, 220, 0.25)',
      },
    },
  },
  plugins: [],
}
