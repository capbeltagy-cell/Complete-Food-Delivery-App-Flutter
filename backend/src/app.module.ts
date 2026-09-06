import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { HealthController } from './health.controller';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { CatalogModule } from './catalog/catalog.module';
import { OrdersModule } from './orders/orders.module';
import { CommunityModule } from './community/community.module';
import { UploadsModule } from './uploads/uploads.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ChatModule } from './chat/chat.module';
import { AdminModule } from './admin/admin.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, cache: true, validate: (env) => {
      for (const key of ['DATABASE_URL','JWT_ACCESS_SECRET','JWT_REFRESH_SECRET','CORS_ORIGINS']) if (!env[key]) throw new Error(`Missing required environment variable: ${key}`);
      if (env.JWT_ACCESS_SECRET.length < 32 || env.JWT_REFRESH_SECRET.length < 32) throw new Error('JWT secrets must be at least 32 characters');
      return env;
    }}),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }]), PrismaModule, AuthModule,
    CatalogModule, OrdersModule, CommunityModule, UploadsModule, NotificationsModule, ChatModule, AdminModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
