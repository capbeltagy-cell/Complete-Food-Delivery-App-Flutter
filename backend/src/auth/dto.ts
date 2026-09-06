import { IsEmail, IsEnum, IsOptional, IsString, Length, Matches } from 'class-validator';
import { Role } from '@prisma/client';
export class RegisterDto {
  @IsEmail() email: string;
  @IsString() @Length(2, 80) name: string;
  @IsString() @Length(10, 100) password: string;
  @IsOptional() @Matches(/^\+?[0-9]{8,15}$/) phone?: string;
  @IsOptional() @IsEnum(Role) role?: Role;
}
export class LoginDto { @IsEmail() email: string; @IsString() password: string; @IsOptional() @IsString() deviceName?: string; }
export class RefreshDto { @IsString() refreshToken: string; }
export class ForgotPasswordDto { @IsEmail() email: string; }
export class ResetPasswordDto { @IsString() token: string; @IsString() @Length(10,100) password: string; }
