import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { Request } from 'express';
import { AuthService } from './auth.service';
import { ForgotPasswordDto, LoginDto, RefreshDto, RegisterDto, ResetPasswordDto } from './dto';
import { JwtGuard } from './jwt.guard';
import { JwtUser } from './auth.types';
@Controller('auth') export class AuthController {
 constructor(private readonly service:AuthService){}
 @Post('register') @Throttle({default:{limit:5,ttl:60000}}) register(@Body() dto:RegisterDto){return this.service.register(dto);}
 @Post('login') @Throttle({default:{limit:5,ttl:60000}}) login(@Body() dto:LoginDto){return this.service.login(dto);}
 @Post('refresh') refresh(@Body() dto:RefreshDto){return this.service.refresh(dto.refreshToken);}
 @UseGuards(JwtGuard) @Post('logout') logout(@Req() req:Request&{user:JwtUser}){return this.service.logout(req.user.sessionId,req.user.sub);}
 @Post('forgot-password') forgot(@Body() dto:ForgotPasswordDto){return this.service.forgot(dto.email);}
 @Post('reset-password') reset(@Body() dto:ResetPasswordDto){return this.service.reset(dto);}
 @UseGuards(JwtGuard) @Get('me') me(@Req() req:Request&{user:JwtUser}){return req.user;}
}
