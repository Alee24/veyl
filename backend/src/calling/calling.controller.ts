import { Controller, Get, Post, Body, Request, UseGuards } from '@nestjs/common';
import { CallingService } from './calling.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('calling')
export class CallingController {
  constructor(private readonly callingService: CallingService) {}

  @UseGuards(JwtAuthGuard)
  @Get('history')
  async getCallHistory(@Request() req: any) {
    return this.callingService.getCallHistory(req.user.userId);
  }

  @Get('ice-servers')
  async getIceServers() {
    return this.callingService.getIceServers();
  }

  @UseGuards(JwtAuthGuard)
  @Post('device-token')
  async registerDeviceToken(
    @Request() req: any,
    @Body('fcmToken') fcmToken: string,
    @Body('platform') platform: 'android' | 'ios' | 'web',
  ) {
    return this.callingService.registerDeviceToken(req.user.userId, fcmToken, platform || 'android');
  }
}
