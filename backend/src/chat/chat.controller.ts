import { Controller, Post, Get, UseGuards, Request, Param, UseInterceptors, UploadedFile, BadRequestException, Body } from '@nestjs/common';
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { randomUUID } from 'crypto';
import { extname } from 'path';

@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get()
  async getUserChats(@Request() req: any) {
    return this.chatService.getUserChats(req.user.userId);
  }

  @Post('direct/:contactId')
  async createDirectChat(@Request() req: any, @Param('contactId') contactId: string) {
    return this.chatService.createDirectChat(req.user.userId, contactId);
  }

  @Get(':chatId/history')
  async getChatHistory(@Param('chatId') chatId: string) {
    return this.chatService.getChatHistory(chatId);
  }

  @Post(':chatId/message')
  async sendMessage(
    @Request() req: any,
    @Param('chatId') chatId: string,
    @Body('content') content: string,
    @Body('type') type?: any
  ) {
    if (!content) {
      throw new BadRequestException('Content is required');
    }
    return this.chatService.saveMessage(chatId, req.user.userId, content, type);
  }

  @Post('upload')
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: './public/uploads',
      filename: (req, file, cb) => {
        const uniqueSuffix = randomUUID() + extname(file.originalname);
        cb(null, uniqueSuffix);
      }
    }),
    limits: { fileSize: 50 * 1024 * 1024 } // 50MB limit
  }))
  async uploadFile(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('File is required');
    }
    // Return relative path for downloading later
    return {
      url: `/uploads/${file.filename}`,
      originalName: file.originalname,
      size: file.size,
      mimetype: file.mimetype,
    };
  }
}
