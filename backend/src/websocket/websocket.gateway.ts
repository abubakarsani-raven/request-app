import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { Injectable, Logger } from '@nestjs/common';

interface AuthenticatedSocket extends Socket {
  userId?: string;
  userRoles?: string[];
}

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: true,
  },
  namespace: '/updates',
})
@Injectable()
export class AppWebSocketGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(AppWebSocketGateway.name);
  private connectedClients = new Map<string, AuthenticatedSocket>();

  constructor(
    private jwtService: JwtService,
    private usersService: UsersService,
  ) {}

  async handleConnection(client: AuthenticatedSocket) {
    try {
      // Extract token from handshake auth or query
      const token =
        client.handshake.auth?.token || client.handshake.query?.token?.toString();

      if (!token) {
        this.logger.warn('Client connected without token');
        client.disconnect();
        return;
      }

      // Verify JWT token (JwtService is already configured with secret from AuthModule)
      const payload = this.jwtService.verify(token);

      // Store user info in socket
      client.userId = payload.sub;
      client.userRoles = payload.roles;

      // Store client connection
      this.connectedClients.set(client.userId, client);

      // Join user-specific room
      client.join(`user:${client.userId}`);

      this.logger.log(`Client connected: ${client.userId}`);
    } catch (error) {
      this.logger.error('Authentication failed', error);
      client.disconnect();
    }
  }

  handleDisconnect(client: AuthenticatedSocket) {
    if (client.userId) {
      this.connectedClients.delete(client.userId);
      this.logger.log(`Client disconnected: ${client.userId}`);
    }
  }

  // Emit to specific user
  emitToUser(userId: string, event: string, data: any) {
    this.server.to(`user:${userId}`).emit(event, data);
  }

  // Emit to all connected clients
  emitToAll(event: string, data: any) {
    this.server.emit(event, data);
  }

  // Emit to users with specific roles
  emitToRoles(roles: string[], event: string, data: any) {
    this.connectedClients.forEach((client, userId) => {
      if (client.userRoles && client.userRoles.some((role) => roles.includes(role))) {
        client.emit(event, data);
      }
    });
  }

  // Request status update
  @SubscribeMessage('request:status:update')
  handleRequestStatusUpdate(
    @MessageBody() data: { requestId: string; status: string; type: string },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    this.logger.log(`Request status update: ${data.requestId}`);
    // Broadcast to relevant users
    this.emitToAll('request:status:changed', data);
  }

  // Trip started notification
  @SubscribeMessage('trip:started')
  handleTripStarted(
    @MessageBody() data: { requestId: string; location: any },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    this.logger.log(`Trip started: ${data.requestId}`);
    // Notify requester and relevant staff
    this.emitToAll('trip:started', data);
  }

  // Destination reached notification
  @SubscribeMessage('trip:destination:reached')
  handleDestinationReached(
    @MessageBody() data: { requestId: string; location: any },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    this.logger.log(`Destination reached: ${data.requestId}`);
    this.emitToAll('trip:destination:reached', data);
  }

  // Trip completed (returned to office) notification
  @SubscribeMessage('trip:completed')
  handleTripCompleted(
    @MessageBody() data: {
      requestId: string;
      location: any;
      totalDistance: number;
      totalFuel: number;
    },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    this.logger.log(`Trip completed: ${data.requestId}`);
    this.emitToAll('trip:completed', data);
  }

  // Location update during trip
  @SubscribeMessage('trip:location:update')
  handleLocationUpdate(
    @MessageBody() data: { requestId: string; location: { lat: number; lng: number } },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    // Broadcast location updates to relevant users (requester, TO, DGS)
    this.emitToAll('trip:location:updated', data);
  }

  // Join request room for real-time updates
  @SubscribeMessage('request:join')
  handleJoinRequest(
    @MessageBody() data: { requestId: string },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    client.join(`request:${data.requestId}`);
    this.logger.log(`Client ${client.userId} joined request room: ${data.requestId}`);
  }

  // Leave request room
  @SubscribeMessage('request:leave')
  handleLeaveRequest(
    @MessageBody() data: { requestId: string },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    client.leave(`request:${data.requestId}`);
    this.logger.log(`Client ${client.userId} left request room: ${data.requestId}`);
  }

  // Emit to specific request room
  emitToRequest(requestId: string, event: string, data: any) {
    this.server.to(`request:${requestId}`).emit(event, data);
  }

  // Emit to multiple users (for workflow participants)
  emitToUsers(userIds: string[], event: string, data: any) {
    userIds.forEach((userId) => {
      this.emitToUser(userId, event, data);
    });
  }
}

