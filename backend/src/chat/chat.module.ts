import { Module } from '@nestjs/common';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { JwtModule } from '@nestjs/jwt';
import { ChatController } from './chat.controller';

@Module({
  imports: [JwtModule],
  providers: [ChatGateway, ChatService],
  exports: [ChatService],
  controllers: [ChatController],
})
export class ChatModule {}
