import { Injectable, UnauthorizedException, ConflictException, BadRequestException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import * as argon2 from 'argon2';
import { FirebaseAdminService } from './firebase-admin.service';
import { randomBytes } from 'crypto';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    private prisma: PrismaService,
    private firebaseAdmin: FirebaseAdminService,
  ) {}

  async validateUser(username: string, pass: string): Promise<any> {
    const user = await this.usersService.findByUsername(username);
    if (user && user.passwordHash && await argon2.verify(user.passwordHash, pass)) {
      const { passwordHash, ...result } = user;
      return result;
    }
    return null;
  }

  async login(user: any, deviceId?: string, ipAddress?: string) {
    const payload = { username: user.username, sub: user.id, isGuest: user.isGuest };
    const tokens = await this.generateTokens(payload);
    
    await this.createSession(user.id, tokens.refreshToken, deviceId, ipAddress);

    return {
      user,
      ...tokens,
    };
  }

  // -------------------------------------------------------------------------
  // Password Recovery via Recovery Key
  // -------------------------------------------------------------------------
  async recoverPassword(username: string, recoveryKey: string, newPassword: string) {
    const user = await this.usersService.findByUsername(username);
    if (!user || !user.recoveryKeyHash) {
      throw new BadRequestException('User not found or recovery not configured');
    }

    const matches = await argon2.verify(user.recoveryKeyHash, recoveryKey);
    if (!matches) {
      throw new UnauthorizedException('Invalid recovery key');
    }

    const newPasswordHash = await argon2.hash(newPassword);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { passwordHash: newPasswordHash },
    });

    return { success: true, message: 'Password reset successfully' };
  }

  async guestLogin(deviceId?: string, ipAddress?: string) {
    const guestUser = await this.usersService.createGuest();
    const payload = { username: guestUser.username, sub: guestUser.id, isGuest: true };
    const tokens = await this.generateTokens(payload);

    await this.createSession(guestUser.id, tokens.refreshToken, deviceId, ipAddress);

    return {
      user: guestUser,
      ...tokens,
    };
  }

  async logout(userId: string, refreshToken: string) {
    await this.prisma.session.deleteMany({
      where: {
        userId,
        refreshToken,
      },
    });
  }

  async refreshTokens(userId: string, refreshToken: string) {
    const session = await this.prisma.session.findUnique({
      where: { refreshToken },
    });

    if (!session || session.userId !== userId) {
      throw new UnauthorizedException('Access Denied');
    }

    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new UnauthorizedException('Access Denied');
    }

    const payload = { username: user.username, sub: user.id, isGuest: user.isGuest };
    const tokens = await this.generateTokens(payload);

    // Replace old session with new one
    await this.prisma.session.delete({ where: { id: session.id } });
    await this.createSession(userId, tokens.refreshToken, session.deviceId ?? undefined, session.ipAddress ?? undefined);

    return tokens;
  }

  private async generateTokens(payload: any) {
    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: process.env.JWT_SECRET || 'veyl_super_secret_dev_key',
        expiresIn: '15m',
      }),
      this.jwtService.signAsync(payload, {
        secret: process.env.JWT_REFRESH_SECRET || 'veyl_super_secret_refresh_dev_key',
        expiresIn: '7d',
      }),
    ]);

    return { accessToken, refreshToken };
  }

  private async createSession(userId: string, refreshToken: string, deviceId?: string, ipAddress?: string) {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

    await this.prisma.session.create({
      data: {
        userId,
        refreshToken,
        deviceId,
        ipAddress,
        expiresAt,
      },
    });
  }
}
