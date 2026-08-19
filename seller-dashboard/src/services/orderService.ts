import api from '../api/client';
import { Order, OrderStatus } from '../types';

export const orderService = {
  // Get orders assigned to the logged-in seller
  getMyOrders: async (): Promise<Order[]> => {
    const res = await api.get('/orders');
    return res.data;
  },

  // Get single order details
  getOrder: async (id: string): Promise<Order> => {
    const res = await api.get(`/orders/${id}`);
    return res.data;
  },

  // Update order status (PENDING -> CONFIRMED -> IN_TRANSIT -> DELIVERED -> CANCELLED)
  updateStatus: async (id: string, status: OrderStatus): Promise<Order> => {
    const res = await api.patch(`/orders/${id}/status`, { status });
    return res.data;
  },

  // Get order tracking info
  getTracking: async (id: string): Promise<any> => {
    const res = await api.get(`/orders/${id}/tracking`);
    return res.data;
  },
};
