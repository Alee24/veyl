import { Module } from '@nestjs/common';
import { CallingService } from './calling.service';
import { CallingController } from './calling.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [CallingController],
  providers: [CallingService],
  exports: [CallingService],
})
export class CallingModule {}
