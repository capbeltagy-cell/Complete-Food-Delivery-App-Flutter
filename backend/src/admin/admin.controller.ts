import{Body,Controller,Get,Param,Patch,UseGuards}from'@nestjs/common';import{ApprovalStatus,Role}from'@prisma/client';import{JwtGuard}from'../auth/jwt.guard';import{Roles}from'../auth/auth.types';import{PrismaService}from'../prisma/prisma.service';
@UseGuards(JwtGuard)@Roles(Role.admin,Role.super_admin)@Controller('admin')export class AdminController{constructor(private readonly p:PrismaService){}
 @Get('dashboard')async dashboard(){const[users,merchants,stores,orders,riders,questions,reports]=await this.p.$transaction([this.p.user.count(),this.p.merchant.count(),this.p.store.count(),this.p.order.count(),this.p.rider.count(),this.p.question.count(),this.p.report.count({where:{status:'open'}})]);return{users,merchants,stores,orders,riders,questions,openReports:reports};}
 @Get('merchants')merchants(){return this.p.merchant.findMany({include:{user:true,stores:true},orderBy:{createdAt:'desc'},take:100});}
 @Patch('merchants/:id/status')merchant(@Param('id')id:string,@Body()b:{status:ApprovalStatus;reason?:string}){if(!Object.values(ApprovalStatus).includes(b.status))throw new Error('Invalid status');return this.p.merchant.update({where:{id},data:{status:b.status,rejectionReason:b.reason,approvedAt:b.status==='approved'?new Date():null}});}
 @Get('orders')orders(){return this.p.order.findMany({include:{store:true,items:true,history:true},orderBy:{createdAt:'desc'},take:200});}
 @Get('reports')reports(){return this.p.report.findMany({orderBy:{createdAt:'desc'},take:200});}
}
