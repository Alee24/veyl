import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { RedisIoAdapter } from './redis.adapter';
import { ValidationPipe } from '@nestjs/common';
import { execSync } from 'child_process';

async function bootstrap() {
  // Automatically run prisma db push on startup to keep schema synced in production
  try {
    console.log('Running database schema sync...');
    execSync('npx prisma db push --accept-data-loss', { stdio: 'inherit' });
    console.log('Database schema sync completed successfully!');
  } catch (error) {
    console.error('Failed to run database schema sync:', error);
  }

  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }));
  app.enableCors();
  
  const redisIoAdapter = new RedisIoAdapter(app);
  await redisIoAdapter.connectToRedis();
  app.useWebSocketAdapter(redisIoAdapter);
  
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
