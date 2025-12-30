import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';
import * as os from 'os';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log', 'debug', 'verbose'],
  });
  
  const logger = new Logger('Bootstrap');
  
  // Enable CORS for mobile and web clients
  app.enableCors({
    origin: true,
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
        return errors;
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

