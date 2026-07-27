import { Controller, Get, Post, Delete, Body, Param, UseGuards, Req, Query, HttpCode, HttpStatus } from '@nestjs/common';
import { LinksService } from './links.service';
import { UsersService } from '../users/users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('links')
export class LinksController {
  constructor(
    private readonly linksService: LinksService,
    private readonly usersService: UsersService,
  ) {}

  @UseGuards(JwtAuthGuard)
  @Post('create')
  async createLink(
    @Req() req: any,
    @Body() body: {
      name?: string;
      expiresInMinutes?: number;
      maxScans?: number;
      allowedActions: string[];
      requireApproval: boolean;
      password?: string;
    },
  ) {
    return this.linksService.createLink(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Get('active')
  async getActiveLinks(@Req() req: any) {
    return this.linksService.getActiveLinks(req.user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  async revokeLink(@Req() req: any, @Param('id') id: string) {
    return this.linksService.revokeLink(req.user.userId, id);
  }

  @Get('verify/:token')
  async verifyToken(@Param('token') token: string) {
    return this.linksService.verifyToken(token);
  }

  @Post('claim/:token')
  @HttpCode(HttpStatus.OK)
  async claimToken(
    @Req() req: any,
    @Param('token') token: string,
    @Body() body: { password?: string; userId?: string },
  ) {
    let userId = req.user?.userId || req.user?.sub || body.userId;
    if (!userId) {
      const guest = await this.usersService.createGuest();
      userId = guest.id;
    }
    return this.linksService.claimToken(token, userId, body.password);
  }
}
