import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { UsersService } from './users/users.service';
import * as bcrypt from 'bcrypt';

async function verifyUser() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const usersService = app.get(UsersService);

  try {
    console.log('🔍 Verifying user: admin@example.com');
    
    const user = await usersService.findByEmail('admin@example.com');
    if (!user) {
      console.log('❌ User not found!');
      await app.close();
      process.exit(1);
    }

    console.log('✅ User found');
    console.log('📧 Email:', user.email);
    console.log('👤 Name:', user.name);
    console.log('🔐 Has password:', !!user.password);
    console.log('🔐 Password type:', typeof user.password);
    console.log('🔐 Password length:', user.password?.length || 0);
    
    if (user.password) {
      console.log('🔐 Password hash starts with:', user.password.substring(0, 10));
      console.log('🔐 Is bcrypt hash:', user.password.startsWith('$2'));
      
      // Test password
      const testPassword = '12345678';
      const isValid = await bcrypt.compare(testPassword, user.password);
      console.log('🔐 Password "12345678" matches:', isValid);
      
      // Test with different variations
      const variations = [
        '12345678',
        ' 12345678',
        '12345678 ',
        '12345678\n',
        '12345678\r',
      ];
      
      for (const variant of variations) {
        const match = await bcrypt.compare(variant, user.password);
        console.log(`🔐 Password "${variant.replace(/\s/g, '\\s')}" matches:`, match);
      }
    } else {
      console.log('❌ User has no password field!');
    }

    await app.close();
    process.exit(0);
  } catch (error: any) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
    await app.close();
    process.exit(1);
  }
}

verifyUser();
