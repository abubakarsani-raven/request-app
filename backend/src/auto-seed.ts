import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { UsersService } from './users/users.service';

/**
 * Auto-seed script that runs on startup if no users exist
 * This ensures the database is seeded when deployed to Railway
 */
async function autoSeed() {
  try {
    const app = await NestFactory.createApplicationContext(AppModule);
    const usersService = app.get(UsersService);

    // Check if any users exist
    const userCount = await usersService.findAll();
    
    if (userCount.length === 0) {
      console.log('🌱 No users found. Running seed script...');
      // Import and run seed
      const { default: seed } = await import('./seed');
      // The seed script will run its bootstrap function
      await app.close();
    } else {
      console.log(`✅ Database already seeded (${userCount.length} users found)`);
      await app.close();
    }
  } catch (error: any) {
    console.error('❌ Auto-seed error:', error.message);
    // Don't throw - allow app to continue
  }
}

// Only run in production or if AUTO_SEED env var is set
if (process.env.NODE_ENV === 'production' || process.env.AUTO_SEED === 'true') {
  autoSeed().catch(console.error);
}
