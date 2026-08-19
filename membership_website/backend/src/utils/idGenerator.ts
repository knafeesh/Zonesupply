import pool from '../config/database';

/**
 * Generates application ID: ZS-APP-000001
 */
export const generateApplicationId = async (): Promise<string> => {
  const result = await pool.query('SELECT COUNT(*) as count FROM applications');
  const count = parseInt(result.rows[0].count, 10) + 1;
  const padded = String(count).padStart(6, '0');
  return `ZS-APP-${padded}`;
};

/**
 * Generates membership ID: ZS100001
 */
export const generateMembershipId = async (): Promise<string> => {
  const result = await pool.query('SELECT COUNT(*) as count FROM memberships');
  const count = parseInt(result.rows[0].count, 10) + 1;
  const base = 100000 + count;
  return `ZS${base}`;
};
