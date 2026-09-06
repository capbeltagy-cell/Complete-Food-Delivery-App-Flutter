import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Role } from '@prisma/client';
import * as argon2 from 'argon2';
import { createHash, randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto, RegisterDto, ResetPasswordDto } from './dto';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService, private readonly jwt: JwtService, private readonly config: ConfigService) {}
  async register(dto: RegisterDto) {
    const email = dto.email.trim().toLowerCase();
    const selfAssignable: Role[] = [Role.customer, Role.merchant, Role.rider];
    if (dto.role && !selfAssignable.includes(dto.role)) throw new BadRequestException('Role cannot be self-assigned');
    const role=dto.role??Role.customer;
    const user = await this.prisma.user.create({data:{email,name:dto.name.trim(),phone:dto.phone,passwordHash:await argon2.hash(dto.password),role,...(role===Role.customer&&{customerProfile:{create:{}}}),...(role===Role.merchant&&{merchant:{create:{businessName:dto.name.trim()}}}),...(role===Role.rider&&{rider:{create:{}}})}});
    return this.issue(user.id, user.role, 'registration');
  }
  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({where:{email:dto.email.trim().toLowerCase()}});
    if (!user?.active || !(await argon2.verify(user.passwordHash,dto.password))) throw new UnauthorizedException('Invalid credentials');
    return this.issue(user.id,user.role,dto.deviceName);
  }
  async refresh(raw: string) {
    let payload: {sub:string;sessionId:string;role:Role};
    try { payload=await this.jwt.verifyAsync(raw,{secret:this.config.getOrThrow('JWT_REFRESH_SECRET')}); } catch { throw new UnauthorizedException(); }
    const session=await this.prisma.session.findUnique({where:{id:payload.sessionId}});
    if(!session||session.revokedAt||session.expiresAt<new Date()||session.tokenHash!==this.hash(raw)) throw new UnauthorizedException();
    const next=await this.issue(payload.sub,payload.role,session.deviceName);
    await this.prisma.session.update({where:{id:session.id},data:{revokedAt:new Date(),replacedById:next.sessionId}});
    return next;
  }
  async logout(sessionId:string,userId:string){await this.prisma.session.updateMany({where:{id:sessionId,userId},data:{revokedAt:new Date()}});return{success:true};}
  async forgot(email:string){
    const user=await this.prisma.user.findUnique({where:{email:email.toLowerCase()}});
    if(user){const token=randomBytes(32).toString('hex');await this.prisma.passwordReset.create({data:{userId:user.id,tokenHash:this.hash(token),expiresAt:new Date(Date.now()+30*60*1000)}});}
    return {success:true};
  }
  async reset(dto:ResetPasswordDto){const reset=await this.prisma.passwordReset.findUnique({where:{tokenHash:this.hash(dto.token)}});if(!reset||reset.usedAt||reset.expiresAt<new Date())throw new BadRequestException('Invalid reset token');await this.prisma.$transaction([this.prisma.user.update({where:{id:reset.userId},data:{passwordHash:await argon2.hash(dto.password)}}),this.prisma.passwordReset.update({where:{id:reset.id},data:{usedAt:new Date()}}),this.prisma.session.updateMany({where:{userId:reset.userId,revokedAt:null},data:{revokedAt:new Date()}})]);return{success:true};}
  private async issue(userId:string,role:Role,deviceName?:string|null){
    const expiresAt=new Date(Date.now()+Number(this.config.get('JWT_REFRESH_DAYS',30))*86400000);
    const session=await this.prisma.session.create({data:{userId,tokenHash:'pending-'+randomBytes(8).toString('hex'),deviceName,expiresAt}});
    const accessToken=await this.jwt.signAsync({sub:userId,role,sessionId:session.id},{secret:this.config.getOrThrow('JWT_ACCESS_SECRET'),expiresIn:this.config.get('JWT_ACCESS_TTL','15m')});
    const refreshToken=await this.jwt.signAsync({sub:userId,role,sessionId:session.id},{secret:this.config.getOrThrow('JWT_REFRESH_SECRET'),expiresIn:`${this.config.get('JWT_REFRESH_DAYS',30)}d`});
    await this.prisma.session.update({where:{id:session.id},data:{tokenHash:this.hash(refreshToken)}});
    return{accessToken,refreshToken,expiresIn:900,sessionId:session.id};
  }
  private hash(value:string){return createHash('sha256').update(value).digest('hex');}
}
