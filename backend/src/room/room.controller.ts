import { Controller, Post, Get, Body, UseGuards, Param, Request } from '@nestjs/common';
import { RoomService } from './room.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('room')
export class RoomController {
  constructor(private readonly roomService: RoomService) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  async createRoom(
    @Request() req: any,
    @Body('name') name: string,
    @Body('type') type: 'PERMANENT' | 'TEMPORARY',
    @Body('durationHours') durationHours?: number,
  ) {
    return this.roomService.createRoom(name, type, durationHours, req.user.userId);
  }

  @Get(':id')
  async getRoom(@Param('id') id: string) {
    return this.roomService.getRoom(id);
  }
}
