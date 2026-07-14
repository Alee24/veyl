import { Injectable, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import * as argon2 from 'argon2';
import { randomBytes } from 'crypto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async create(createUserDto: CreateUserDto) {
    const existingUser = await this.prisma.user.findUnique({
      where: { username: createUserDto.username },
    });

    if (existingUser) {
      throw new ConflictException('Username is already taken');
    }

    const passwordHash = await argon2.hash(createUserDto.password);
    const qrCode = randomBytes(16).toString('hex'); // Unique identifier for QR link

    return this.prisma.user.create({
      data: {
        username: createUserDto.username,
        passwordHash,
        displayName: createUserDto.displayName,
        bio: createUserDto.bio,
        qrCode,
      },
    });
  }

  async createGuest() {
    // Generate a random guest username
    const guestId = randomBytes(4).toString('hex').toUpperCase();
    const username = `Guest-${guestId}`;
    const qrCode = randomBytes(16).toString('hex');

    // Guests expire in 24 hours
    const guestExpiresAt = new Date();
    guestExpiresAt.setHours(guestExpiresAt.getHours() + 24);

    return this.prisma.user.create({
      data: {
        username,
        displayName: `Guest ${guestId}`,
        qrCode,
        isGuest: true,
        guestExpiresAt,
      },
    });
  }

  async findByUsername(username: string) {
    return this.prisma.user.findUnique({
      where: { username },
    });
  }

  async findById(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
    });
  }

  async findByQrCode(qrCode: string) {
    return this.prisma.user.findUnique({
      where: { qrCode },
    });
  }
}
