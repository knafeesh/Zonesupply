import { Request, Response } from 'express';
import pool from '../config/database';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { generateMembershipId } from '../utils/idGenerator';
import { AuthRequest } from '../middleware/auth';

// ─── Admin Login ─────────────────────────────────────────────
export const adminLogin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      res.status(400).json({ success: false, message: 'Username and password are required.' });
      return;
    }

    const result = await pool.query(
      'SELECT * FROM admin WHERE username = $1',
      [username]
    );

    if (result.rows.length === 0) {
      res.status(401).json({ success: false, message: 'Invalid credentials.' });
      return;
    }

    const admin = result.rows[0];
    const isValid = await bcrypt.compare(password, admin.password_hash);

    if (!isValid) {
      res.status(401).json({ success: false, message: 'Invalid credentials.' });
      return;
    }

    const token = jwt.sign(
      { id: admin.id, username: admin.username },
      process.env.JWT_SECRET || 'secret',
      { expiresIn: '1d' }
    );

    res.json({
      success: true,
      message: 'Login successful',
      token,
      admin: { id: admin.id, username: admin.username },
      data: {
        token,
        admin: { id: admin.id, username: admin.username },
      },
    });
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── Get All Applications ─────────────────────────────────────
export const getAllApplications = async (req: Request, res: Response): Promise<void> => {
  try {
    const { status, page = '1', limit = '20' } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const params: any[] = [];
    let whereClause = '';

    if (status && ['pending', 'approved', 'rejected'].includes(String(status))) {
      params.push(String(status));
      whereClause = `WHERE a.status = $${params.length}`;
    }

    params.push(Number(limit));
    params.push(offset);

    const query = `
      SELECT a.application_id, a.full_name, a.mobile, a.email,
             a.shop_name, a.business_type, a.city, a.state,
             a.status, a.created_at, m.membership_id
      FROM applications a
      LEFT JOIN memberships m ON a.application_id = m.application_id
      ${whereClause}
      ORDER BY a.created_at DESC
      LIMIT $${params.length - 1} OFFSET $${params.length}
    `;

    const [appsResult, statsResult] = await Promise.all([
      pool.query(query, params),
      pool.query(`
        SELECT
          COUNT(*) as total,
          COUNT(*) FILTER (WHERE status = 'pending') as pending,
          COUNT(*) FILTER (WHERE status = 'approved') as approved,
          COUNT(*) FILTER (WHERE status = 'rejected') as rejected
        FROM applications
      `),
    ]);

    const stats = statsResult.rows[0];

    res.json({
      success: true,
      data: appsResult.rows,
      stats: {
        total: parseInt(stats.total, 10),
        pending: parseInt(stats.pending, 10),
        approved: parseInt(stats.approved, 10),
        rejected: parseInt(stats.rejected, 10),
      },
      pagination: { page: Number(page), limit: Number(limit) },
    });
  } catch (error) {
    console.error('Get applications error:', error);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── Get Single Application ───────────────────────────────────
export const getApplicationById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const [appResult, docsResult] = await Promise.all([
      pool.query(
        `SELECT a.*, m.membership_id FROM applications a
         LEFT JOIN memberships m ON a.application_id = m.application_id
         WHERE a.application_id = $1`,
        [id]
      ),
      pool.query(
        'SELECT doc_type, file_name, file_path FROM documents WHERE application_id = $1',
        [id]
      ),
    ]);

    if (appResult.rows.length === 0) {
      res.status(404).json({ success: false, message: 'Application not found.' });
      return;
    }

    res.json({
      success: true,
      data: { ...appResult.rows[0], documents: docsResult.rows },
    });
  } catch (error) {
    console.error('Get application error:', error);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── Approve Application ──────────────────────────────────────
export const approveApplication = async (req: AuthRequest, res: Response): Promise<void> => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { applicationId } = req.body;
    const adminId = req.admin?.id;

    const appResult = await client.query(
      "SELECT * FROM applications WHERE application_id = $1 AND status = 'pending'",
      [applicationId]
    );

    if (appResult.rows.length === 0) {
      res.status(404).json({ success: false, message: 'Pending application not found.' });
      await client.query('ROLLBACK');
      return;
    }

    const app = appResult.rows[0];
    const membershipId = await generateMembershipId();

    await client.query(
      "UPDATE applications SET status = 'approved', updated_at = NOW() WHERE application_id = $1",
      [applicationId]
    );

    await client.query(
      `INSERT INTO memberships
       (membership_id, application_id, retailer_name, shop_name, mobile, email, city, state, approved_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
      [membershipId, applicationId, app.full_name, app.shop_name, app.mobile, app.email, app.city, app.state, adminId]
    );

    await client.query(
      `INSERT INTO retailers
       (membership_id, application_id, full_name, shop_name, mobile, email,
        business_type, gst_number, address, city, state, pincode)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
      [membershipId, applicationId, app.full_name, app.shop_name, app.mobile, app.email,
       app.business_type, app.gst_number, app.address, app.city, app.state, app.pincode]
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Application approved successfully!',
      data: { applicationId, membershipId, status: 'approved' },
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Approve error:', error);
    res.status(500).json({ success: false, message: 'Server error.' });
  } finally {
    client.release();
  }
};

// ─── Reject Application ───────────────────────────────────────
export const rejectApplication = async (req: Request, res: Response): Promise<void> => {
  try {
    const { applicationId, reason } = req.body;

    if (!applicationId || !reason) {
      res.status(400).json({ success: false, message: 'applicationId and reason are required.' });
      return;
    }

    const result = await pool.query(
      `UPDATE applications SET status = 'rejected', rejection_reason = $1, updated_at = NOW()
       WHERE application_id = $2 AND status = 'pending'`,
      [reason, applicationId]
    );

    if (result.rowCount === 0) {
      res.status(404).json({ success: false, message: 'Pending application not found.' });
      return;
    }

    res.json({
      success: true,
      message: 'Application rejected.',
      data: { applicationId, status: 'rejected' },
    });
  } catch (error) {
    console.error('Reject error:', error);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
};
