import { Controller, Get, Param, Post, Body, UseGuards, NotFoundException, BadRequestException } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @UseGuards(JwtAuthGuard)
  @Post('match-contacts')
  async matchContacts(@Body('phoneNumbers') phoneNumbers: string[]) {
    if (!phoneNumbers || !Array.isArray(phoneNumbers)) {
      throw new BadRequestException('phoneNumbers list is required');
    }
    return this.usersService.matchPhoneNumbers(phoneNumbers);
  }

  @Get(':username')
  async findByUsername(@Param('username') username: string) {
    const user = await this.usersService.findByUsername(username);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    const { passwordHash, ...safeUser } = user;
    return safeUser;
  }
}
