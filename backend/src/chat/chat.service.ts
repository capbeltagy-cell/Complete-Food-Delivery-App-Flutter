import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class ChatService {
  constructor(private readonly prisma: PrismaService, private readonly notifications: NotificationsService) {}
  async messages(orderId: string, userId: string, cursor?: string) {
    const conversation = await this.conversation(orderId, userId, false);
    if (!conversation) return [];
    await this.prisma.chatParticipant.upsert({ where: { conversationId_userId: { conversationId: conversation.id, userId } }, create: { conversationId: conversation.id, userId, lastReadAt: new Date() }, update: { lastReadAt: new Date() } });
    return this.prisma.chatMessage.findMany({ where: { conversationId: conversation.id, deletedAt: null, ...(cursor && { id: { lt: cursor } }) }, include: { sender: { select: { id: true, name: true, role: true, avatarUrl: true } } }, orderBy: { createdAt: 'desc' }, take: 50 });
  }
  async send(orderId: string, userId: string, body: string, type = 'text') {
    if (!body.trim() || body.length > 2000 || !['text', 'arrived'].includes(type)) throw new ForbiddenException('Invalid message');
    const conversation = await this.conversation(orderId, userId, true);
    await this.prisma.chatParticipant.upsert({ where: { conversationId_userId: { conversationId: conversation.id, userId } }, create: { conversationId: conversation.id, userId }, update: {} });
    const message = await this.prisma.chatMessage.create({ data: { conversationId: conversation.id, senderId: userId, body: body.trim(), type }, include: { sender: { select: { id: true, name: true, role: true, avatarUrl: true } } } });
    const order = await this.prisma.order.findUniqueOrThrow({ where: { id: orderId }, include: { store: { include: { merchant: true } }, rider: true } });
    const recipients = [order.customerId, order.store.merchant.userId, order.rider?.userId].filter((id): id is string => !!id && id !== userId);
    await Promise.all(recipients.map((id) => this.notifications.create(id, type === 'arrived' ? 'المندوب وصل' : 'رسالة جديدة', body.trim(), 'chat_message', orderId).catch(() => null)));
    return message;
  }
  private async conversation(orderId: string, userId: string, create: true): Promise<{ id: string }>;
  private async conversation(orderId: string, userId: string, create: false): Promise<{ id: string } | null>;
  private async conversation(orderId: string, userId: string, create: boolean) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId }, include: { store: { include: { merchant: true } }, rider: true, conversation: true } });
    if (!order) throw new NotFoundException('Order not found');
    if (![order.customerId, order.store.merchant.userId, order.rider?.userId].includes(userId)) throw new ForbiddenException();
    if (order.conversation) return order.conversation;
    return create ? this.prisma.conversation.create({ data: { orderId, type: 'order' } }) : null;
  }
}
