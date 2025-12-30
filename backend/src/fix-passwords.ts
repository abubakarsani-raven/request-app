import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { UsersService } from './users/users.service';
import * as bcrypt from 'bcrypt';

async function fixPasswords() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const usersService = app.get(UsersService);

  try {
    console.log('🔧 Starting password fix process...');

    // List of users and their passwords
    const usersToFix = [
      { email: 'admin@example.com', password: '12345678' },
      { email: 'administrator@example.com', password: 'Admin@2024' },
      { email: 'driver@example.com', password: 'Driver@2024' },
      { email: 'supervisor@example.com', password: 'Supervisor@2024' },
      { email: 'ddict@example.com', password: 'DDICT@2024' },
      { email: 'storeofficer@example.com', password: 'SO@2024' },
      { email: 'ddgs@example.com', password: 'DDGS@2024' },
      { email: 'adgs@example.com', password: 'ADGS@2024' },
      { email: 'transportofficer@example.com', password: 'TO@2024' },
      { email: 'ictadmin@example.com', password: 'ICTAdmin@2024' },
      { email: 'storeadmin@example.com', password: 'StoreAdmin@2024' },
      { email: 'transportadmin@example.com', password: 'TransportAdmin@2024' },
    ];

    for (const userData of usersToFix) {
      try {
        const user = await usersService.findByEmail(userData.email);
        if (user) {
          // Re-hash the password
          const hashedPassword = await bcrypt.hash(userData.password, 10);
          (user as any).password = hashedPassword;
          await (user as any).save();
          console.log(`✅ Fixed password for: ${userData.email}`);
        } else {
          console.log(`⚠️  User not found: ${userData.email}`);
        }
      } catch (error: any) {
        console.error(`❌ Error fixing ${userData.email}:`, error.message);
      }
    }

    console.log('✨ Password fix process completed!');
    await app.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    await app.close();
    process.exit(1);
  }
}

fixPasswords();
