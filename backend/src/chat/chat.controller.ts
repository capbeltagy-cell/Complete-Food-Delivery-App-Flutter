import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { IsIn, IsOptional, IsString, Length } from 'class-validator';
import { Request } from 'express';
import { JwtUser } from '../auth/auth.types';
import { JwtGuard } from '../auth/jwt.guard';
import { ChatService } from './chat.service';
class SendMessageDto { @IsString() @Length(1, 2000) body: string; @IsOptional() @IsIn(['text', 'arrived']) type?: string; }
@UseGuards(JwtGuard) @Controller('orders/:orderId/chat')
export class ChatController {
  constructor(private readonly service: ChatService) {}
  @Get() list(@Req() req: Request & { user: JwtUser }, @Param('orderId') orderId: string, @Query('cursor') cursor?: string) { return this.service.messages(orderId, req.user.sub, cursor); }
  @Post() send(@Req() req: Request & { user: JwtUser }, @Param('orderId') orderId: string, @Body() dto: SendMessageDto) { return this.service.send(orderId, req.user.sub, dto.body, dto.type); }
}
