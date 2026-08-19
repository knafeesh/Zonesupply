import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
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
  },
});
