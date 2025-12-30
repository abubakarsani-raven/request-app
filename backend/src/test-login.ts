import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { UsersService } from './users/users.service';
import { AuthService } from './auth/auth.service';
import * as bcrypt from 'bcrypt';

async function testLogin() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const usersService = app.get(UsersService);
  const authService = app.get(AuthService);

  try {
    console.log('🔍 Testing login for admin@example.com...');
    
    // Check if user exists
    const user = await usersService.findByEmail('admin@example.com');
    if (!user) {
      console.log('❌ User not found!');
      await app.close();
      process.exit(1);
    }

    console.log('✅ User found:', user.email);
    console.log('📧 Email:', user.email);
    console.log('🔐 Password hash exists:', !!user.password);
    console.log('🔐 Password hash length:', user.password?.length || 0);
    console.log('🔐 Password hash preview:', user.password?.substring(0, 20) + '...');

    // Test password comparison directly
    const testPassword = '12345678';
    const isMatch = await bcrypt.compare(testPassword, user.password);
    console.log('🔐 Direct bcrypt compare result:', isMatch);

    // Test via auth service
    console.log('\n🔍 Testing via AuthService...');
    try {
      const result = await authService.validateUser('admin@example.com', '12345678');
      if (result) {
        console.log('✅ AuthService validation: SUCCESS');
        console.log('👤 User ID:', result._id);
      } else {
        console.log('❌ AuthService validation: FAILED');
      }
    } catch (error: any) {
      console.log('❌ AuthService validation error:', error.message);
    }

    // Test login endpoint
    console.log('\n🔍 Testing login endpoint...');
    try {
      const loginResult = await authService.login({
        email: 'admin@example.com',
        password: '12345678',
      });
      console.log('✅ Login successful!');
      console.log('🎫 Token generated:', !!loginResult.access_token);
    } catch (error: any) {
      console.log('❌ Login failed:', error.message);
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

testLogin();
