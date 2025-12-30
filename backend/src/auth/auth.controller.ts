import { Controller, Post, Body, UseGuards, Get, Logger, HttpCode, HttpStatus } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { LocalAuthGuard } from './guards/local-auth.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { JwtRefreshGuard } from './guards/jwt-refresh.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';

@Controller('auth')
export class AuthController {
  private readonly logger = new Logger(AuthController.name);

  constructor(
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
  ) {}

  @Get('health')
  health() {
    this.logger.log('Health check endpoint called');
    return { status: 'ok', message: 'Auth endpoint is working' };
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 attempts per minute
  async login(@Body() loginDto: LoginDto) {
    this.logger.log(`Login attempt for email: ${loginDto.email}`);
    this.logger.log(`Received email: ${loginDto.email}, password length: ${loginDto.password?.length || 0}`);
    this.logger.log(`Password preview: ${loginDto.password?.substring(0, 3)}***`);
    try {
      const result = await this.authService.login(loginDto);
      this.logger.log(`Login successful for email: ${loginDto.email}`);
      return result;
    } catch (error) {
      this.logger.error(`Login failed for email: ${loginDto.email}`);
      this.logger.error(`Error details: ${error.message}`);
      // Additional debug: check if user exists
      const user = await this.usersService.findByEmail(loginDto.email);
      if (user) {
        this.logger.log(`User exists: ${user.email}, has password: ${!!user.password}`);
      } else {
        this.logger.log(`User NOT found: ${loginDto.email}`);
      }
      throw error;
    }
  }

  @Post('refresh')
  @UseGuards(JwtRefreshGuard)
  async refresh(@CurrentUser() user: any) {
    return this.authService.refreshToken(user);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMe(@CurrentUser() user: any) {
    return user;
  }

  @Post('register')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 3, ttl: 60000 } }) // 3 registrations per minute
  async register(@Body() createUserDto: CreateUserDto) {
    this.logger.log(`Registration attempt for email: ${createUserDto.email}`);
    try {
      const user = await this.usersService.create(createUserDto);
      this.logger.log(`User registered successfully: ${createUserDto.email}`);
      return user;
    } catch (error) {
      this.logger.error(`Registration failed for email: ${createUserDto.email}`, error.stack);
      throw error;
    }
  }
}

