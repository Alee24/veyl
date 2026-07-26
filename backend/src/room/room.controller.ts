import { Controller, Post, Get, Body, Param, Request } from '@nestjs/common';
import { RoomService } from './room.service';

@Controller('room')
export class RoomController {
  constructor(private readonly roomService: RoomService) {}

  @Post()
  async createRoom(
    @Request() req: any,
    @Body('name') name: string,
    @Body('type') type: 'PERMANENT' | 'TEMPORARY',
    @Body('durationHours') durationHours?: number,
    @Body('presenterId') presenterIdBody?: string,
  ) {
    const userId = presenterIdBody || req.user?.userId || req.user?.sub;
    return this.roomService.createRoom(name, type, durationHours, userId);
  }

  @Get()
  async getActiveRooms() {
    return this.roomService.getActiveRooms();
  }

  @Get(':id')
  async getRoom(@Param('id') id: string) {
    return this.roomService.getRoom(id);
  }
}
