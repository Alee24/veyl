import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class RoomService {
  constructor(private prisma: PrismaService) {}

  async createRoom(name: string, type: 'PERMANENT' | 'TEMPORARY', durationHours?: number, presenterId?: string) {
    if (!name) {
      throw new BadRequestException('Room name is required');
    }

    let finalPresenterId = presenterId;
    if (!finalPresenterId) {
      const defaultUser = await this.getDefaultPresenter();
      finalPresenterId = defaultUser.id;
    }
    
    let expiresAt: Date | null = null;
    if (type === 'TEMPORARY') {
      if (!durationHours || durationHours <= 0) {
        durationHours = 3;
      }
      expiresAt = new Date();
      expiresAt.setHours(expiresAt.getHours() + durationHours);
    }

    return this.prisma.room.create({
      data: {
        name,
        type,
        expiresAt,
        presenterId: finalPresenterId,
      },
      include: {
        presenter: {
          select: {
            id: true,
            username: true,
            displayName: true,
            profilePhotoUrl: true,
          }
        }
      }
    });
  }

  async getDefaultPresenter() {
    let user = await this.prisma.user.findFirst();
    if (!user) {
      user = await this.prisma.user.create({
        data: {
          username: 'host',
          displayName: 'Host Presenter',
          qrCode: 'host_qr_' + Math.random().toString(36).substring(7),
        }
      });
    }
    return user;
  }

  async getActiveRooms() {
    return this.prisma.room.findMany({
      orderBy: { createdAt: 'desc' },
      take: 50,
      include: {
        presenter: {
          select: {
            id: true,
            username: true,
            displayName: true,
            profilePhotoUrl: true,
          }
        }
      }
    });
  }

  async getRoom(id: string) {
    let room = await this.prisma.room.findUnique({
      where: { id },
      include: {
        presenter: {
          select: {
            id: true,
            username: true,
            displayName: true,
            profilePhotoUrl: true,
          }
        }
      }
    });

    if (!room) {
      const defaultUser = await this.getDefaultPresenter();
      try {
        room = await this.prisma.room.create({
          data: {
            id: id.length > 10 ? id : undefined,
            name: 'Podcast Studio #' + id.substring(0, 6),
            type: 'TEMPORARY',
            presenterId: defaultUser.id,
          },
          include: {
            presenter: {
              select: {
                id: true,
                username: true,
                displayName: true,
                profilePhotoUrl: true,
              }
            }
          }
        });
      } catch (_) {
        // If creation with specific ID fails, fetch first or default room
        room = await this.prisma.room.findFirst({
          include: {
            presenter: {
              select: {
                id: true,
                username: true,
                displayName: true,
                profilePhotoUrl: true,
              }
            }
          }
        });
      }
    }

    if (!room) {
      const defaultUser = await this.getDefaultPresenter();
      room = await this.createRoom('Live Podcast Room', 'TEMPORARY', 24, defaultUser.id);
    }

    return room;
  }
}
