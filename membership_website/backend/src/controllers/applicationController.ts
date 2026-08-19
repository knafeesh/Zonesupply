import { Request, Response } from 'express';
import pool from '../config/database';
import { generateApplicationId } from '../utils/idGenerator';

interface ApplicationFiles {
  aadhaar?: Express.Multer.File[];
  pan?: Express.Multer.File[];
  shopPhoto?: Express.Multer.File[];
  gstCert?: Express.Multer.File[];
}

export const submitApplication = async (req: Request, res: Response): Promise<void> => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const {
      fullName, mobile, email, shopName, businessType,
      gstNumber, address, state, city, pincode, termsAccepted,
    } = req.body;

    // Check duplicate mobile
    const existing = await client.query(
      'SELECT id FROM applications WHERE mobile = $1',
      [mobile]
    );
    if (existing.rows.length > 0) {
      res.status(409).json({
        success: false,
        message: 'An application with this mobile number already exists.',
      });
      await client.query('ROLLBACK');
      return;
    }

    const applicationId = await generateApplicationId();
    const ipAddress = req.ip || req.socket.remoteAddress || null;

    await client.query(
      `INSERT INTO applications
        (application_id, full_name, mobile, email, shop_name, business_type,
         gst_number, address, state, city, pincode, terms_accepted, ip_address)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)`,
      [
        applicationId, fullName, mobile, email, shopName, businessType,
        gstNumber || null, address, state, city, pincode,
        termsAccepted === 'true', ipAddress,
      ]
    );

    // Insert documents
    const files = req.files as unknown as ApplicationFiles;
    const docMap: Record<string, string> = {
      aadhaar: 'aadhaar',
      pan: 'pan',
      shopPhoto: 'shop_photo',
      gstCert: 'gst_cert',
    };

    for (const [fieldName, dbDocType] of Object.entries(docMap)) {
      const fileArray = files[fieldName as keyof ApplicationFiles];
      if (fileArray && fileArray[0]) {
        const file = fileArray[0];
        await client.query(
          `INSERT INTO documents (application_id, doc_type, file_name, file_path, file_size, mime_type)
           VALUES ($1,$2,$3,$4,$5,$6)`,
          [applicationId, dbDocType, file.originalname, file.path, file.size, file.mimetype]
        );
      }
    }

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      message: 'Application submitted successfully!',
      data: {
        applicationId,
        status: 'pending',
        submittedAt: new Date().toISOString(),
      },
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    console.error('Error submitting application:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit application. Please try again.',
    });
  } finally {
    client.release();
  }
};
