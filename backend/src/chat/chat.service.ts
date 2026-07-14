import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export type MessageType = 'TEXT' | 'IMAGE' | 'VIDEO' | 'AUDIO' | 'FILE' | 'VOICE_NOTE';

@Injectable()
export class ChatService {
  constructor(private prisma: PrismaService) {}

  async createDirectChat(userId: string, contactId: string) {
    // Check if a direct chat already exists
    const existingChat = await this.prisma.chat.findFirst({
      where: {
        type: 'DIRECT',
        participants: {
          every: {
            userId: { in: [userId, contactId] }
          }
        }
      }
    });

    if (existingChat) return existingChat;

    return this.prisma.chat.create({
      data: {
        type: 'DIRECT',
        participants: {
          create: [
            { userId },
            { userId: contactId }
          ]
        }
      },
      include: { participants: true }
    });
  }

  async saveMessage(chatId: string, senderId: string, content: string, type: MessageType = 'TEXT') {
    return this.prisma.message.create({
      data: {
        chatId,
        senderId,
        content,
        type,
      },
      include: { sender: { select: { id: true, username: true, displayName: true, profilePhotoUrl: true } } }
    });
  }

  async getChatHistory(chatId: string, limit = 50, before?: string) {
    const whereClause: any = { chatId };
    if (before) {
      whereClause.createdAt = { lt: new Date(before) };
    }
    
    return this.prisma.message.findMany({
      where: whereClause,
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: { sender: { select: { id: true, username: true, displayName: true, profilePhotoUrl: true } } }
    });
  }

  async updateMessageStatus(messageId: string, status: 'DELIVERED' | 'READ') {
    return this.prisma.message.update({
      where: { id: messageId },
      data: { status }
    });
  }
}
