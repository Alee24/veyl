import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as crypto from 'crypto';

@Injectable()
export class LinksService {
  constructor(private prisma: PrismaService) {}

  async createLink(
    ownerId: string,
    data: {
      name?: string;
      expiresInMinutes?: number;
      maxScans?: number;
      allowedActions: string[];
      requireApproval: boolean;
      password?: string;
    },
  ) {
    const secureToken = crypto.randomBytes(6).toString('base64url'); // ~8 chars cryptographically secure
    
    let expiresAt: Date | null = null;
    if (data.expiresInMinutes) {
      expiresAt = new Date();
      expiresAt.setMinutes(expiresAt.getMinutes() + data.expiresInMinutes);
    }

    return this.prisma.temporaryLink.create({
      data: {
        ownerId,
        secureToken,
        name: data.name,
        expiresAt,
        maxScans: data.maxScans,
        allowedActions: data.allowedActions,
        requireApproval: data.requireApproval,
        password: data.password || null, // PIN/Password
      },
    });
  }

  async getActiveLinks(ownerId: string) {
    // Auto-update expired links before returning
    await this.cleanupExpiredLinks();

    return this.prisma.temporaryLink.findMany({
      where: {
        ownerId,
        status: 'ACTIVE',
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async revokeLink(ownerId: string, linkId: string) {
    const link = await this.prisma.temporaryLink.findUnique({
      where: { id: linkId },
    });

    if (!link) {
      throw new NotFoundException('Link not found');
    }

    if (link.ownerId !== ownerId) {
      throw new ForbiddenException('Cannot revoke other user\'s link');
    }

    return this.prisma.temporaryLink.update({
      where: { id: linkId },
      data: { status: 'REVOKED' },
    });
  }

  async verifyToken(token: string) {
    await this.cleanupExpiredLinks();

    const link = await this.prisma.temporaryLink.findUnique({
      where: { secureToken: token },
      include: {
        owner: {
          select: {
            username: true,
            displayName: true,
          },
        },
      },
    });

    if (!link || link.status !== 'ACTIVE') {
      throw new NotFoundException('Invitation has expired or is invalid');
    }

    // Double check manual expiration
    if (link.expiresAt && new Date() > link.expiresAt) {
      await this.prisma.temporaryLink.update({
        where: { id: link.id },
        data: { status: 'EXPIRED' },
      });
      throw new NotFoundException('Invitation has expired');
    }

    if (link.maxScans && link.currentScans >= link.maxScans) {
      await this.prisma.temporaryLink.update({
        where: { id: link.id },
        data: { status: 'EXPIRED' },
      });
      throw new NotFoundException('Invitation usage limit reached');
    }

    // Don't return password in verification endpoint
    const { password, ...safeLink } = link;
    return safeLink;
  }

  async claimToken(token: string, claimerId: string, passwordInput?: string) {
    const link = await this.verifyToken(token);

    if (link.ownerId === claimerId) {
      throw new BadRequestException('You cannot scan your own link');
    }

    // Verify PIN if required
    const fullLinkObj = await this.prisma.temporaryLink.findUnique({
      where: { id: link.id },
    });
    if (fullLinkObj?.password && fullLinkObj.password !== passwordInput) {
      throw new ForbiddenException('Invalid PIN code');
    }

    // Increment scan counts
    const updated = await this.prisma.temporaryLink.update({
      where: { id: link.id },
      data: {
        currentScans: { increment: 1 },
      },
    });

    // Check if limit hit to auto-expire
    if (updated.maxScans && updated.currentScans >= updated.maxScans) {
      await this.prisma.temporaryLink.update({
        where: { id: link.id },
        data: { status: 'EXPIRED' },
      });
    }

    // Check if a chat already exists between these users
    const existingChat = await this.prisma.chat.findFirst({
      where: {
        type: 'DIRECT',
        participants: {
          every: {
            userId: { in: [link.ownerId, claimerId] },
          },
        },
      },
    });

    if (existingChat) {
      return { chatId: existingChat.id, status: 'CONNECTED' };
    }

    // Create the secure direct chat session
    const chat = await this.prisma.chat.create({
      data: {
        type: 'DIRECT',
        participants: {
          create: [
            { userId: link.ownerId, role: 'ADMIN' },
            { userId: claimerId, role: 'MEMBER' },
          ],
        },
      },
    });

    // Send an automated system greeting message
    await this.prisma.message.create({
      data: {
        chatId: chat.id,
        senderId: link.ownerId,
        content: `👋 Session started via temporary invite: "${link.name || 'Invite Link'}"`,
        type: 'TEXT',
        status: 'SENT',
      },
    });

    return { chatId: chat.id, status: 'CONNECTED' };
  }

  private async cleanupExpiredLinks() {
    const now = new Date();
    // Expire by time
    await this.prisma.temporaryLink.updateMany({
      where: {
        status: 'ACTIVE',
        expiresAt: { lt: now },
      },
      data: { status: 'EXPIRED' },
    });
  }
}
