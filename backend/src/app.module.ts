import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CacheModule } from '@nestjs/cache-manager';
import { BullModule } from '@nestjs/bullmq';
import * as redisStore from 'cache-manager-ioredis';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { ProductsModule } from './products/products.module';
import { OrdersModule } from './orders/orders.module';
import { ConsolidationModule } from './consolidation/consolidation.module';
import { DeliveryModule } from './delivery/delivery.module';
import { PaymentModule } from './payment/payment.module';
import { NotificationsModule } from './notifications/notifications.module';
import { MapsModule } from './maps/maps.module';
import { ZonesModule } from './zones/zones.module';
import { WholesalersModule } from './wholesalers/wholesalers.module';
import { RetailersModule } from './retailers/retailers.module';
import { DeliveryPartnersModule } from './delivery-partners/delivery-partners.module';
import { CreditLedgerModule } from './credit-ledger/credit-ledger.module';
import { AdminModule } from './admin/admin.module';
import { BannersModule } from './banners/banners.module';
import { SellerLedgerModule } from './seller-ledger/seller-ledger.module';

@Module({
  imports: [
    // Config
    ConfigModule.forRoot({ isGlobal: true }),

    // PostgreSQL via TypeORM
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({
        type: 'postgres',
        host: cfg.get('DB_HOST', 'localhost'),
        port: cfg.get<number>('DB_PORT', 5432),
        database: cfg.get('DB_NAME', 'zonesupply_db'),
        username: cfg.get('DB_USER', 'zonesupply_user'),
        password: cfg.get('DB_PASS', 'zonesupply_pass'),
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        synchronize: cfg.get('NODE_ENV') !== 'production', // auto-migration in dev
        logging: cfg.get('NODE_ENV') === 'development',
      }),
    }),

    // Redis Cache
    CacheModule.registerAsync({
      isGlobal: true,
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({
        store: redisStore,
        host: cfg.get('REDIS_HOST', 'localhost'),
        port: cfg.get<number>('REDIS_PORT', 6379),
        ttl: 300, // 5 minutes default
      }),
    }),

    // BullMQ Queue Configuration
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({
        connection: {
          host: cfg.get('REDIS_HOST', 'localhost'),
          port: cfg.get<number>('REDIS_PORT', 6379),
        },
      }),
    }),

    // Feature modules
    AuthModule,
    UsersModule,
    ProductsModule,
    OrdersModule,
    ConsolidationModule,
    DeliveryModule,
    PaymentModule,
    NotificationsModule,
    MapsModule,
    ZonesModule,
    WholesalersModule,
    RetailersModule,
    DeliveryPartnersModule,
    CreditLedgerModule,
    AdminModule,
    BannersModule,
    SellerLedgerModule,
  ],
})
export class AppModule {}
