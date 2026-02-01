import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger, BadRequestException } from '@nestjs/common';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';
import { UsersService } from './users/users.service';
import * as os from 'os';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log', 'debug', 'verbose'],
  });
  
  const logger = new Logger('Bootstrap');

  // Auto-seed database if empty (for Railway/production deployments)
  try {
    const usersService = app.get(UsersService);
    const users = await usersService.findAll();
    if (users.length === 0) {
      logger.log('🌱 No users found. Auto-seeding database...');
      try {
        // Import and run seed
        const { runSeed } = await import('./seed');
        await runSeed();
        logger.log('✅ Database seeded successfully');
        // Verify users were created
        const newUsers = await usersService.findAll();
        logger.log(`✅ Verified: ${newUsers.length} users now exist in database`);
      } catch (seedError: any) {
        logger.error(`❌ Seed failed: ${seedError.message}`);
        logger.error(`❌ Stack: ${seedError.stack}`);
        logger.warn('⚠️  Continuing startup without seeding. Run seed manually.');
      }
    } else {
      logger.log(`✅ Database already has ${users.length} users`);
    }
  } catch (error: any) {
    logger.error(`❌ Auto-seed check failed: ${error.message}`);
    logger.error(`❌ Stack: ${error.stack}`);
    logger.warn('⚠️  Continuing startup...');
  }
  
  // Enable CORS for mobile and web clients
  const corsOrigin =
    process.env.NODE_ENV === 'production' && process.env.CORS_ORIGINS
      ? process.env.CORS_ORIGINS.split(',').map((o) => o.trim()).filter(Boolean)
      : true;
  app.enableCors({
    origin: corsOrigin,
    credentials: true,
  });

  // Enable WebSocket adapter
  // WebSocket is automatically enabled via @WebSocketGateway decorator

  // Add Morgan HTTP request logger (development mode)
  if (process.env.NODE_ENV !== 'production') {
    try {
      const morgan = require('morgan');
      app.use(
        morgan('dev', {
          stream: {
            write: (message: string) => {
              logger.log(message.trim());
            },
          },
        }),
      );
      logger.log('✅ Morgan HTTP logger enabled');
    } catch (error) {
      logger.warn('⚠️  Morgan not installed. Run: npm install morgan @types/morgan --save-dev');
    }
  }

  // Global validation pipe with better error messages
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      exceptionFactory: (errors) => {
        logger.error('Validation failed', errors);
        const message = errors
          .map((e) => Object.values(e.constraints || {}).join(', '))
          .join('; ');
        throw new BadRequestException(message || 'Validation failed');
      },
    }),
  );

  // Global exception filter for better error logging
  app.useGlobalFilters(new AllExceptionsFilter());

  const port = process.env.PORT || 4000;
  // Listen on all network interfaces (0.0.0.0) to allow connections from mobile devices
  await app.listen(port, '0.0.0.0');
  
  // Get network interfaces to show available IPs
  const networkInterfaces = os.networkInterfaces();
  const localIPs: string[] = [];
  
  Object.keys(networkInterfaces).forEach((interfaceName) => {
    const addresses = networkInterfaces[interfaceName];
    if (addresses) {
      addresses.forEach((addr) => {
        if (addr.family === 'IPv4' && !addr.internal) {
          localIPs.push(addr.address);
        }
      });
    }
  });

  logger.log('\n🚀 Application is running!');
  logger.log(`📍 Local: http://localhost:${port}`);
  if (localIPs.length > 0) {
    logger.log(`\n📱 For mobile devices on the same network, use:`);
    localIPs.forEach((ip) => {
      logger.log(`   http://${ip}:${port}`);
    });
    logger.log(`\n💡 Update your mobile app's API URL to one of the above IPs`);
  }
  logger.log('');
}
bootstrap();

