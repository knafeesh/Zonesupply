import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { fileURLToPath, URL } from 'node:url';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    port: 5174,
    host: true,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:3000',
        changeOrigin: true,
      },
      '/auth': {
        target: 'http://127.0.0.1:3000/api/v1',
        changeOrigin: true,
      },
      '/users': {
        target: 'http://127.0.0.1:3000/api/v1',
        changeOrigin: true,
      },
      '/products': {
        target: 'http://127.0.0.1:3000/api/v1',
        changeOrigin: true,
      },
      '/orders': {
        target: 'http://127.0.0.1:3000/api/v1',
        changeOrigin: true,
      },
      '/wholesalers': {
        target: 'http://127.0.0.1:3000/api/v1',
        changeOrigin: true,
      },
      '/banners': {
        target: 'http://127.0.0.1:3000/api/v1',
        changeOrigin: true,
      },
      '/uploads': {
        target: 'http://127.0.0.1:3000',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    chunkSizeWarningLimit: 1000,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
          charts: ['recharts'],
          ui: ['lucide-react', 'clsx', 'tailwind-merge'],
        },
      },
    },
  },
});
