import { Request, Response } from 'express';
import pool from '../config/database';

export const checkStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const { applicationId, mobile } = req.query;

    if (!applicationId && !mobile) {
      res.status(400).json({
        success: false,
        message: 'Please provide applicationId or mobile number.',
      });
      return;
    }

    let query: string;
    let params: string[];

    if (applicationId) {
      query = `
        SELECT a.application_id, a.full_name, a.shop_name, a.status,
               a.rejection_reason, a.created_at, a.updated_at,
               m.membership_id
        FROM applications a
        LEFT JOIN memberships m ON a.application_id = m.application_id
        WHERE a.application_id = $1
      `;
      params = [String(applicationId)];
    } else {
      query = `
        SELECT a.application_id, a.full_name, a.shop_name, a.status,
               a.rejection_reason, a.created_at, a.updated_at,
               m.membership_id
        FROM applications a
        LEFT JOIN memberships m ON a.application_id = m.application_id
        WHERE a.mobile = $1
      `;
      params = [String(mobile)];
    }

    const result = await pool.query(query, params);

    if (result.rows.length === 0) {
      res.status(404).json({
        success: false,
        message: 'No application found with the provided details.',
      });
      return;
    }

    const app = result.rows[0];
    res.json({
      success: true,
      data: {
        applicationId: app.application_id,
        fullName: app.full_name,
        shopName: app.shop_name,
        status: app.status,
        rejectionReason: app.rejection_reason || null,
        membershipId: app.membership_id || null,
        submittedAt: app.created_at,
        updatedAt: app.updated_at,
      },
    });
  } catch (error) {
    console.error('Error checking status:', error);
    res.status(500).json({ success: false, message: 'Server error. Please try again.' });
  }
};

/**
 * Dedicated endpoint for Retailer App to verify membership before login.
 * ONLY approved members with active membership are allowed.
 */
export const verifyRetailerMembership = async (req: Request, res: Response): Promise<void> => {
  try {
    const { identifier } = req.body;

    if (!identifier || String(identifier).trim().length === 0) {
      res.status(400).json({
        success: false,
        isApproved: false,
        status: 'invalid_input',
        message: 'Please enter your Membership ID or Mobile Number.',
      });
      return;
    }

    const cleanInput = String(identifier).trim();

    // 1. Check if active membership exists
    const membershipQuery = `
      SELECT m.membership_id, m.application_id, m.retailer_name, m.shop_name,
             m.mobile, m.email, m.city, m.state, m.membership_status
      FROM memberships m
      WHERE m.membership_id = $1 OR m.mobile = $1 OR m.application_id = $1
    `;
    const memResult = await pool.query(membershipQuery, [cleanInput]);

    if (memResult.rows.length > 0) {
      const mem = memResult.rows[0];
      if (mem.membership_status === 'active') {
        res.json({
          success: true,
          isApproved: true,
          status: 'approved',
          membershipId: mem.membership_id,
          retailer: {
            fullName: mem.retailer_name,
            shopName: mem.shop_name,
            mobile: mem.mobile,
            email: mem.email,
            city: mem.city,
            state: mem.state,
          },
        });
        return;
      } else {
        res.status(403).json({
          success: false,
          isApproved: false,
          status: 'suspended',
          message: 'Your membership is suspended. Please contact Zone Store support.',
        });
        return;
      }
    }

    // 2. If not found in memberships, check applications status
    const appQuery = `
      SELECT application_id, full_name, shop_name, status, rejection_reason
      FROM applications
      WHERE application_id = $1 OR mobile = $1
    `;
    const appResult = await pool.query(appQuery, [cleanInput]);

    if (appResult.rows.length > 0) {
      const app = appResult.rows[0];
      if (app.status === 'pending') {
        res.status(403).json({
          success: false,
          isApproved: false,
          status: 'pending',
          applicationId: app.application_id,
          message: `Your membership application (${app.application_id}) is currently PENDING approval from the Zone Store team. You will be able to log in once approved.`,
        });
        return;
      } else if (app.status === 'rejected') {
        res.status(403).json({
          success: false,
          isApproved: false,
          status: 'rejected',
          applicationId: app.application_id,
          message: `Your membership application was REJECTED: ${app.rejection_reason || 'Documents could not be verified'}. Please apply again.`,
        });
        return;
      }
    }

    // 3. Not found anywhere
    res.status(404).json({
      success: false,
      isApproved: false,
      status: 'not_found',
      message: 'No membership or application found for this ID/Mobile. Please apply for retailer membership first.',
    });
  } catch (error) {
    console.error('Error verifying membership:', error);
    res.status(500).json({ success: false, isApproved: false, message: 'Server error while checking membership.' });
  }
};
