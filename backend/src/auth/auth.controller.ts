import { Controller, Post, Body, Request, UseGuards, Get, HttpCode, HttpStatus } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import { FirebaseRegisterDto } from './dto/firebase-register.dto';
import { JwtAuthGuard } from './jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private usersService: UsersService,
  ) {}

  @Post('register')
  async register(@Body() createUserDto: CreateUserDto) {
    const user = await this.usersService.create(createUserDto);
    // Auto-login after register
    return this.authService.login(user);
  }

  @Post('firebase-register')
  async firebaseRegister(
    @Body() dto: FirebaseRegisterDto,
    @Request() req: any,
  ) {
    const deviceId = req.headers['x-device-id'] as string | undefined;
    const ipAddress = req.ip as string | undefined;
    return this.authService.firebaseRegister(
      dto.firebaseToken,
      dto.username,
      dto.displayName,
      deviceId,
      ipAddress,
    );
  }

  @HttpCode(HttpStatus.OK)
  @Post('login')
  async login(@Body() loginDto: LoginDto, @Request() req: any) {
    const user = await this.authService.validateUser(loginDto.username, loginDto.password);
    if (!user) {
      return { statusCode: 401, message: 'Invalid credentials' };
    }
    const deviceId = req.headers['x-device-id'] as string;
    const ipAddress = req.ip;
    return this.authService.login(user, deviceId, ipAddress);
  }

  @HttpCode(HttpStatus.OK)
  @Post('guest')
  async guestLogin(@Request() req: any) {
    const deviceId = req.headers['x-device-id'] as string;
    const ipAddress = req.ip;
    return this.authService.guestLogin(deviceId, ipAddress);
  }

  @HttpCode(HttpStatus.OK)
  @Post('refresh')
  async refreshTokens(@Body('refreshToken') refreshToken: string, @Request() req: any) {
    const userId = req.body.userId; // Should ideally extract from validated request or payload
    if (!userId || !refreshToken) {
      return { statusCode: 401, message: 'Missing tokens' };
    }
    return this.authService.refreshTokens(userId, refreshToken);
  }

  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post('logout')
  async logout(@Request() req: any, @Body('refreshToken') refreshToken: string) {
    return this.authService.logout(req.user.userId, refreshToken);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  getProfile(@Request() req: any) {
    return this.usersService.findById(req.user.userId);
  }
}
