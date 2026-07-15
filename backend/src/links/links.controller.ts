import { Controller, Get, Post, Delete, Body, Param, UseGuards, Req, Query, HttpCode, HttpStatus } from '@nestjs/common';
import { LinksService } from './links.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('links')
export class LinksController {
  constructor(private readonly linksService: LinksService) {}

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

  @UseGuards(JwtAuthGuard)
  @Post('claim/:token')
  @HttpCode(HttpStatus.OK)
  async claimToken(
    @Req() req: any,
    @Param('token') token: string,
    @Body() body: { password?: string },
  ) {
    return this.linksService.claimToken(token, req.user.userId, body.password);
  }
}
