import { Router } from 'express';
import { submitApplication } from '../controllers/applicationController';
import { upload } from '../middleware/upload';
import { validateApplication, handleValidationErrors } from '../middleware/validate';
import { applyRateLimiter } from '../middleware/rateLimit';

const router = Router();

router.post(
  '/apply',
  applyRateLimiter,
  upload.fields([
    { name: 'aadhaar', maxCount: 1 },
    { name: 'pan', maxCount: 1 },
    { name: 'shopPhoto', maxCount: 1 },
    { name: 'gstCert', maxCount: 1 },
  ]),
  validateApplication,
  handleValidationErrors,
  submitApplication
);

export { router as applicationRoutes };
