import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../../users/users.service';
import { UserDocument } from '../../users/schemas/user.schema';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private usersService: UsersService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET') || 'your-secret-key',
    });
  }

  async validate(payload: any) {
    const user = await this.usersService.findOne(payload.sub);
    if (!user) {
      throw new UnauthorizedException();
    }
    const userDoc = user as any as UserDocument;
    // Ensure _id and id are strings (convert ObjectId if needed)
    const userId = userDoc._id?.toString() || userDoc.id?.toString() || String(userDoc._id || userDoc.id);
    return {
      _id: userId,
      id: userId,
      email: user.email,
      name: user.name,
      departmentId: user.departmentId,
      level: user.level,
      roles: user.roles,
      supervisorId: user.supervisorId,
    };
  }
}

