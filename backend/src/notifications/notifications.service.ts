import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from './notification.entity';
import { User } from '../users/user.entity';

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly cfg: ConfigService,
    @InjectRepository(Notification)
    private readonly notificationRepo: Repository<Notification>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async sendToUser(
    userId: string,
    payload: { title: string; message: string; type?: string },
  ): Promise<Notification> {
    // 1. Save to database
    const notification = this.notificationRepo.create({
      userId,
      title: payload.title,
      message: payload.message,
      type: payload.type,
      readStatus: false,
    });
    const saved = await this.notificationRepo.save(notification);

    // 2. Fetch User FCM Token and attempt push delivery
    const user = await this.userRepo.findOneBy({ id: userId });
    if (user && user.fcmToken) {
      try {
        await this.sendToDevice(user.fcmToken, {
          title: payload.title,
          body: payload.message,
          data: { type: payload.type || '' },
        });
      } catch (err) {
        this.logger.error(`Failed to push FCM to user ${userId}: ${err.message}`);
      }
    }

    return saved;
  }

  async sendToDevice(fcmToken: string, payload: PushPayload): Promise<void> {
    this.logger.log(
      `[STUB] Push to token=${fcmToken.substring(0, 12)}... | title="${payload.title}"`,
    );
  }

  async sendToMultiple(fcmTokens: string[], payload: PushPayload): Promise<void> {
    this.logger.log(`[STUB] Push to ${fcmTokens.length} devices | title="${payload.title}"`);
    await Promise.all(fcmTokens.map((t) => this.sendToDevice(t, payload)));
  }

  async notifyOrderStatus(fcmToken: string, orderId: string, status: string): Promise<void> {
    await this.sendToDevice(fcmToken, {
      title: 'Order Update',
      body: `Your order is now: ${status}`,
      data: { orderId, status },
    });
  }

  async getUserNotifications(userId: string): Promise<Notification[]> {
    return this.notificationRepo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async markAsRead(id: string): Promise<void> {
    await this.notificationRepo.update(id, { readStatus: true });
  }
}
