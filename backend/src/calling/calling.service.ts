import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CallingService {
  constructor(private prisma: PrismaService) {}

  async createCallRecord(callerId: string, receiverId: string, type: 'VOICE' | 'VIDEO') {
    return this.prisma.call.create({
      data: {
        callerId,
        receiverId,
        type,
        status: 'ONGOING',
      },
    });
  }

  async updateCallStatus(callId: string, status: 'ANSWERED' | 'REJECTED' | 'MISSED' | 'ONGOING', duration?: number) {
    return this.prisma.call.update({
      where: { id: callId },
      data: {
        status,
        endedAt: status === 'ONGOING' ? undefined : new Date(),
        duration,
      },
    });
  }

  async registerDeviceToken(userId: string, fcmToken: string, platform: 'android' | 'ios' | 'web') {
    return this.prisma.deviceToken.upsert({
      where: { fcmToken },
      update: { userId, platform, updatedAt: new Date() },
      create: { userId, fcmToken, platform },
    });
  }

  async getCallHistory(userId: string) {
    return this.prisma.call.findMany({
      where: {
        OR: [
          { callerId: userId },
          { receiverId: userId },
        ],
      },
      orderBy: { startedAt: 'desc' },
      take: 50,
      include: {
        caller: {
          select: {
            id: true,
            username: true,
            displayName: true,
            profilePhotoUrl: true,
          },
        },
        receiver: {
          select: {
            id: true,
            username: true,
            displayName: true,
            profilePhotoUrl: true,
          },
        },
      },
    });
  }

  async getIceServers() {
    return {
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' },
        { urls: 'stun:stun2.l.google.com:19302' },
        {
          urls: [
            'turn:veyl.kkdes.co.ke:3478?transport=udp',
            'turn:veyl.kkdes.co.ke:3478?transport=tcp',
          ],
          username: 'veylturn',
          credential: 'veylturnpassword',
        },
      ],
    };
  }
}
