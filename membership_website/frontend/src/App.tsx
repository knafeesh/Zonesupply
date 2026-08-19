import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AdminAuthProvider } from './context/AdminAuthContext';
import LandingPage from './pages/LandingPage';
import ApplicationForm from './pages/ApplicationForm';
import SuccessPage from './pages/SuccessPage';
import CheckStatus from './pages/CheckStatus';
import AdminLogin from './pages/admin/AdminLogin';
import AdminDashboard from './pages/admin/AdminDashboard';
import { useAdminAuth } from './context/AdminAuthContext';

// Protected route wrapper for admin
const AdminRoute = ({ children }: { children: React.ReactNode }) => {
  const { isAuthenticated } = useAdminAuth();
  return isAuthenticated ? <>{children}</> : <Navigate to="/admin" replace />;
};

function AppRoutes() {
  return (
    <Routes>
      {/* Public Routes */}
      <Route path="/" element={<LandingPage />} />
      <Route path="/apply" element={<ApplicationForm />} />
      <Route path="/success/:appId" element={<SuccessPage />} />
      <Route path="/check-status" element={<CheckStatus />} />

      {/* Hidden Admin Routes — NOT linked anywhere on public site */}
      <Route path="/admin" element={<AdminLogin />} />
      <Route
        path="/admin/dashboard"
        element={
          <AdminRoute>
            <AdminDashboard />
          </AdminRoute>
        }
      />

      {/* Fallback */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

function App() {
  return (
    <AdminAuthProvider>
      <BrowserRouter>
        <AppRoutes />
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              background: '#0071dc',
              color: '#fff',
              borderRadius: '12px',
              fontFamily: 'Inter, sans-serif',
              fontSize: '14px',
              fontWeight: '500',
            },
            success: {
              style: { background: '#065f46', color: '#fff' },
              iconTheme: { primary: '#34d399', secondary: '#fff' },
            },
            error: {
              style: { background: '#991b1b', color: '#fff' },
              iconTheme: { primary: '#fca5a5', secondary: '#fff' },
            },
          }}
        />
      </BrowserRouter>
    </AdminAuthProvider>
  );
}

export default App;
