import { Router } from 'express';
import { checkStatus, verifyRetailerMembership } from '../controllers/statusController';
import { statusRateLimiter } from '../middleware/rateLimit';

const router = Router();

router.get('/status', statusRateLimiter, checkStatus);
router.post('/check-membership', statusRateLimiter, verifyRetailerMembership);

export { router as statusRoutes };
