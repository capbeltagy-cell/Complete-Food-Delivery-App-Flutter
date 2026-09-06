import { Controller, Get, Param, Patch, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { JwtUser } from '../auth/auth.types';
import { JwtGuard } from '../auth/jwt.guard';
import { NotificationsService } from './notifications.service';

@UseGuards(JwtGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}
  @Get() list(@Req() req: Request & { user: JwtUser }) { return this.service.list(req.user.sub); }
  @Get('unread-count') unreadCount(@Req() req: Request & { user: JwtUser }) { return this.service.unreadCount(req.user.sub); }
  @Patch('read-all') readAll(@Req() req: Request & { user: JwtUser }) { return this.service.readAll(req.user.sub); }
  @Patch(':id/read') read(@Req() req: Request & { user: JwtUser }, @Param('id') id: string) { return this.service.read(req.user.sub, id); }
}
