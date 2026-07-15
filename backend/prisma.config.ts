// prisma.config.ts
import { defineConfig } from 'prisma/config';
import 'dotenv/config';

// @ts-ignore - Bypass Prisma version configuration type differences between local v6 and VPS v7
export default defineConfig({
  schema: './prisma/schema.prisma',
  
  // Prisma 6 classic engine configuration
  engine: 'classic',
  datasource: {
    url: process.env.DATABASE_URL || '',
  },

  // Prisma 7 configuration shorthand (silenced via ts-ignore)
  datasourceUrl: process.env.DATABASE_URL,
} as any);
