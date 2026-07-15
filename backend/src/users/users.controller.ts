import { Controller, Get, Param, Post, Body, UseGuards, NotFoundException, BadRequestException, Request, UseInterceptors, UploadedFile } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { randomUUID } from 'crypto';
import { extname } from 'path';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}


  @UseGuards(JwtAuthGuard)
  @Post('profile-photo')
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: './public/uploads',
      filename: (req, file, cb) => {
        const uniqueSuffix = randomUUID() + extname(file.originalname);
        cb(null, uniqueSuffix);
      }
    }),
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
  }))
  async uploadProfilePhoto(@Request() req: any, @UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('File is required');
    }
    const photoUrl = `/uploads/${file.filename}`;
    return this.usersService.updateProfilePhoto(req.user.userId, photoUrl);
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
