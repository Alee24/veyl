import { 
  WebSocketGateway, 
  WebSocketServer, 
  SubscribeMessage, 
  OnGatewayConnection, 
  OnGatewayDisconnect, 
  ConnectedSocket, 
  MessageBody 
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';
import { JwtService } from '@nestjs/jwt';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(
    private chatService: ChatService,
    private jwtService: JwtService
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token || client.handshake.headers['authorization']?.split(' ')[1];
      if (!token) {
        client.disconnect();
        return;
      }
      const payload = await this.jwtService.verifyAsync(token, { secret: process.env.JWT_SECRET || 'veyl_super_secret_dev_key' });
      client.data.user = payload;
      
      // User joins their personal room to receive private events
      client.join(payload.sub);
    } catch (e) {
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    // Notify others about offline status? (Can be implemented via presence service)
  }

  @SubscribeMessage('join_chat')
  async handleJoinChat(@ConnectedSocket() client: Socket, @MessageBody() chatId: string) {
    client.join(`chat_${chatId}`);
  }

  @SubscribeMessage('leave_chat')
  async handleLeaveChat(@ConnectedSocket() client: Socket, @MessageBody() chatId: string) {
    client.leave(`chat_${chatId}`);
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket, 
    @MessageBody() payload: { chatId: string; content: string; type?: any }
  ) {
    const userId = client.data.user.sub;
    const message = await this.chatService.saveMessage(payload.chatId, userId, payload.content, payload.type);

    this.server.to(`chat_${payload.chatId}`).emit('new_message', message);
    return message;
  }

  @SubscribeMessage('typing')
  async handleTyping(
    @ConnectedSocket() client: Socket, 
    @MessageBody() payload: { chatId: string; isTyping: boolean }
  ) {
    const userId = client.data.user.sub;
    client.to(`chat_${payload.chatId}`).emit('user_typing', { userId, chatId: payload.chatId, isTyping: payload.isTyping });
  }

  @SubscribeMessage('message_status')
  async handleMessageStatus(
    @ConnectedSocket() client: Socket, 
    @MessageBody() payload: { messageId: string; chatId: string; status: 'DELIVERED' | 'READ' }
  ) {
    const message = await this.chatService.updateMessageStatus(payload.messageId, payload.status);
    client.to(`chat_${payload.chatId}`).emit('message_status_update', { messageId: message.id, status: message.status });
  }
}
