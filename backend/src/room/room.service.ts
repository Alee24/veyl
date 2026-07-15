import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class RoomService {
  constructor(private prisma: PrismaService) {}

  async createRoom(name: string, type: 'PERMANENT' | 'TEMPORARY', durationHours?: number, presenterId?: string) {
    if (!name) {
      throw new BadRequestException('Room name is required');
    }

    if (!presenterId) {
      throw new BadRequestException('Presenter ID is required to create a room');
    }
    
    let expiresAt: Date | null = null;
    if (type === 'TEMPORARY') {
      if (!durationHours || durationHours <= 0) {
        throw new BadRequestException('Valid duration is required for temporary rooms');
      }
      expiresAt = new Date();
      expiresAt.setHours(expiresAt.getHours() + durationHours);
    }

    return this.prisma.room.create({
      data: {
        name,
        type,
        expiresAt,
        presenterId,
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

  async getRoom(id: string) {
    const room = await this.prisma.room.findUnique({
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
      throw new NotFoundException('Room not found');
    }

    // Check if temporary room is expired
    if (room.type === 'TEMPORARY' && room.expiresAt && new Date() > new Date(room.expiresAt)) {
      // Clean up/delete expired room
      await this.prisma.room.delete({ where: { id } }).catch(() => {});
      throw new BadRequestException('This room has expired');
    }

    return room;
  }
}
