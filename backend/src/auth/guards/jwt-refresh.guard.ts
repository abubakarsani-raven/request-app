import { Injectable, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { ExtractJwt } from 'passport-jwt';
import { UsersService } from '../../users/users.service';
import { UserDocument } from '../../users/schemas/user.schema';

@Injectable()
export class JwtRefreshGuard {
  constructor(
    private configService: ConfigService,
    private jwtService: JwtService,
    private usersService: UsersService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    
    // Try multiple ways to extract the token
    let token = ExtractJwt.fromAuthHeaderAsBearerToken()(request);
    
    // If not found in Authorization header, try headers directly
    if (!token && request.headers) {
      const authHeader = request.headers.authorization || request.headers.Authorization;
      if (authHeader && typeof authHeader === 'string' && authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7);
      }
    }

    if (!token) {
      throw new UnauthorizedException('No token provided');
    }

    try {
      // First, try to verify the token (works if not expired)
      let payload: any;
      try {
        payload = this.jwtService.verify(token, {
          secret: this.configService.get<string>('JWT_SECRET') || 'your-secret-key',
        });
      } catch (verifyError: any) {
        // If token is expired, decode it without verification
        if (verifyError.name === 'TokenExpiredError') {
          payload = this.jwtService.decode(token) as any;
          if (!payload || !payload.sub) {
            throw new UnauthorizedException('Invalid token payload');
          }
        } else {
          // For other errors (invalid signature, etc.), reject
          throw new UnauthorizedException('Invalid token');
        }
      }

      // Verify user still exists
      const user = await this.usersService.findOne(payload.sub);
      if (!user) {
        throw new UnauthorizedException('User not found');
      }

      // Attach user to request
      const userDoc = user as any as UserDocument;
      const userId = userDoc._id?.toString() || userDoc.id?.toString() || String(userDoc._id || userDoc.id);
      
      request.user = {
        _id: userId,
        id: userId,
        email: user.email,
        name: user.name,
        departmentId: user.departmentId,
        level: user.level,
        roles: user.roles,
        supervisorId: user.supervisorId,
      };

      return true;
    } catch (error: any) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      throw new UnauthorizedException('Token validation failed');
    }
  }
}

