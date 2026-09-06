import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}
  create(userId: string, title: string, body: string, type: string, orderId?: string) { return this.prisma.notification.create({ data: { userId, title, body, type, orderId } }); }
  list(userId: string) { return this.prisma.notification.findMany({ where: { userId }, take: 100, orderBy: { createdAt: 'desc' } }); }
  async unreadCount(userId: string) { return { count: await this.prisma.notification.count({ where: { userId, readAt: null } }) }; }
  async read(userId: string, id: string) {
    const notification = await this.prisma.notification.findFirst({ where: { id, userId } });
    if (!notification) throw new NotFoundException('Notification not found');
    return this.prisma.notification.update({ where: { id }, data: { readAt: notification.readAt ?? new Date() } });
  }
  async readAll(userId: string) {
    const result = await this.prisma.notification.updateMany({ where: { userId, readAt: null }, data: { readAt: new Date() } });
    return { updated: result.count };
  }
}
