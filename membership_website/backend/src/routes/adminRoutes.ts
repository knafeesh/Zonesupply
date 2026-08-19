import { Router } from 'express';
import {
  adminLogin,
  getAllApplications,
  getApplicationById,
  approveApplication,
  rejectApplication,
} from '../controllers/adminController';
import { authenticateAdmin } from '../middleware/auth';
import { adminLoginRateLimiter } from '../middleware/rateLimit';

const router = Router();

// Public admin routes
router.post('/login', adminLoginRateLimiter, adminLogin);

// Protected admin routes
router.get('/applications', authenticateAdmin, getAllApplications);
router.get('/applications/:id', authenticateAdmin, getApplicationById);
router.post('/approve', authenticateAdmin, approveApplication);
router.post('/reject', authenticateAdmin, rejectApplication);

export { router as adminRoutes };
