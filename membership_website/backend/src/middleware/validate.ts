import { body, validationResult } from 'express-validator';
import { Request, Response, NextFunction } from 'express';

export const validateApplication = [
  body('fullName')
    .trim()
    .isLength({ min: 3, max: 100 })
    .withMessage('Full name must be between 3 and 100 characters'),
  body('mobile')
    .matches(/^[6-9]\d{9}$/)
    .withMessage('Enter a valid 10-digit Indian mobile number'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Enter a valid email address'),
  body('shopName')
    .trim()
    .isLength({ min: 2, max: 150 })
    .withMessage('Shop name must be between 2 and 150 characters'),
  body('businessType')
    .isIn(['grocery', 'pharmacy', 'electronics', 'clothing', 'restaurant', 'hardware', 'cosmetics', 'stationery', 'other'])
    .withMessage('Invalid business type'),
  body('gstNumber')
    .optional({ nullable: true, checkFalsy: true })
    .matches(/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/)
    .withMessage('Enter a valid GST number'),
  body('address')
    .trim()
    .isLength({ min: 10, max: 500 })
    .withMessage('Address must be at least 10 characters'),
  body('state')
    .trim()
    .notEmpty()
    .withMessage('State is required'),
  body('city')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Enter a valid city name'),
  body('pincode')
    .matches(/^[1-9][0-9]{5}$/)
    .withMessage('Enter a valid 6-digit pincode'),
  body('termsAccepted')
    .equals('true')
    .withMessage('You must accept the Terms & Conditions'),
];

export const handleValidationErrors = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array(),
    });
    return;
  }
  next();
};
