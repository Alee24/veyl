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

    if (createUserDto.phoneNumber) {
      const existingPhone = await this.prisma.user.findUnique({
        where: { phoneNumber: createUserDto.phoneNumber },
      });
      if (existingPhone) {
        throw new ConflictException('Phone number is already registered');
      }
    }

    const passwordHash = await argon2.hash(createUserDto.password);
    const qrCode = randomBytes(16).toString('hex'); // Unique identifier for QR link

    return this.prisma.user.create({
      data: {
        username: createUserDto.username,
        passwordHash,
        displayName: createUserDto.displayName,
        bio: createUserDto.bio,
        phoneNumber: createUserDto.phoneNumber,
        qrCode,
      },
    });
  }

  async matchPhoneNumbers(numbers: string[]) {
    const cleanNumbers = numbers.map(num => num.replace(/\D/g, ''));
    
    const allUsers = await this.prisma.user.findMany({
      where: {
        phoneNumber: { not: null }
      },
      select: {
        id: true,
        username: true,
        displayName: true,
        phoneNumber: true,
        profilePhotoUrl: true,
        status: true
      }
    });

    return allUsers.filter(user => {
      if (!user.phoneNumber) return false;
      const userClean = user.phoneNumber.replace(/\D/g, '');
      return cleanNumbers.some(inputClean => {
        if (inputClean.length >= 9 && userClean.length >= 9) {
          return inputClean.endsWith(userClean.slice(-9)) || userClean.endsWith(inputClean.slice(-9));
        }
        return inputClean === userClean;
      });
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
        profilePhotoUrl: `https://api.dicebear.com/7.x/bottts/png?seed=${guestId}`,
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

  async updateProfilePhoto(userId: string, profilePhotoUrl: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { profilePhotoUrl },
      select: {
        id: true,
        username: true,
        displayName: true,
        profilePhotoUrl: true,
        bio: true,
        phoneNumber: true,
        qrCode: true,
      }
    });
  }
}
