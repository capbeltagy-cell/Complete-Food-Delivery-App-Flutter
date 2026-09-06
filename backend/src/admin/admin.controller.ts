import { BadRequestException, Body, Controller, Get, Param, Patch, UseGuards } from '@nestjs/common';
import { ApprovalStatus, ContentStatus, Role } from '@prisma/client';
import { JwtGuard } from '../auth/jwt.guard'; import { Roles } from '../auth/auth.types'; import { PrismaService } from '../prisma/prisma.service';
@UseGuards(JwtGuard) @Roles(Role.admin,Role.super_admin) @Controller('admin')
export class AdminController{constructor(private readonly p:PrismaService){}
 @Get('dashboard')async dashboard(){const[users,merchants,stores,products,orders,riders,questions,reports]=await this.p.$transaction([this.p.user.count(),this.p.merchant.count(),this.p.store.count(),this.p.product.count(),this.p.order.count(),this.p.rider.count(),this.p.question.count(),this.p.report.count({where:{status:'open'}})]);return{users,merchants,stores,products,orders,riders,questions,openReports:reports};}
 @Get('users')users(){return this.p.user.findMany({select:{id:true,email:true,phone:true,name:true,role:true,active:true,verifiedAt:true,createdAt:true},orderBy:{createdAt:'desc'},take:200});}
 @Patch('users/:id/active')userActive(@Param('id')id:string,@Body()b:{active:boolean}){if(typeof b.active!=='boolean')throw new BadRequestException();return this.p.user.update({where:{id},data:{active:b.active}});}
 @Get('merchants')merchants(){return this.p.merchant.findMany({include:{user:true,stores:true},orderBy:{createdAt:'desc'},take:200});}
 @Patch('merchants/:id/status')merchant(@Param('id')id:string,@Body()b:{status:ApprovalStatus;reason?:string}){if(!Object.values(ApprovalStatus).includes(b.status))throw new BadRequestException('Invalid status');return this.p.$transaction(async tx=>{const merchant=await tx.merchant.update({where:{id},data:{status:b.status,rejectionReason:b.reason,approvedAt:b.status==='approved'?new Date():null}});await tx.store.updateMany({where:{merchantId:id,deletedAt:null},data:{status:b.status,isOpen:b.status==='approved'?undefined:false}});return merchant;});}
 @Get('stores')stores(){return this.p.store.findMany({include:{merchant:{include:{user:true}},category:true},orderBy:{createdAt:'desc'},take:200});}
 @Get('products')products(){return this.p.product.findMany({where:{deletedAt:null},include:{store:true,images:true},orderBy:{createdAt:'desc'},take:200});}
 @Get('categories')categories(){return this.p.category.findMany({orderBy:{sortOrder:'asc'}});}
 @Patch('categories/:id/active')category(@Param('id')id:string,@Body()b:{active:boolean}){if(typeof b.active!=='boolean')throw new BadRequestException();return this.p.category.update({where:{id},data:{active:b.active}});}
 @Get('orders')orders(){return this.p.order.findMany({include:{store:true,customer:{select:{id:true,name:true,phone:true}},rider:{include:{user:true}},items:true,history:true},orderBy:{createdAt:'desc'},take:200});}
 @Get('riders')riders(){return this.p.rider.findMany({include:{user:true},orderBy:{createdAt:'desc'},take:200});}
 @Patch('riders/:id/status')rider(@Param('id')id:string,@Body()b:{status:ApprovalStatus}){if(!Object.values(ApprovalStatus).includes(b.status))throw new BadRequestException();return this.p.rider.update({where:{id},data:{status:b.status,available:b.status==='approved'?undefined:false}});}
 @Get('questions')questions(){return this.p.question.findMany({include:{author:{select:{id:true,name:true,role:true}},answers:true},orderBy:{createdAt:'desc'},take:200});}
 @Patch('questions/:id/status')question(@Param('id')id:string,@Body()b:{status:ContentStatus}){if(!Object.values(ContentStatus).includes(b.status))throw new BadRequestException();return this.p.question.update({where:{id},data:{status:b.status}});}
 @Get('reports')reports(){return this.p.report.findMany({include:{reporter:{select:{id:true,name:true,role:true}}},orderBy:{createdAt:'desc'},take:200});}
 @Patch('reports/:id/status')report(@Param('id')id:string,@Body()b:{status:string}){if(!['open','resolved','dismissed'].includes(b.status))throw new BadRequestException();return this.p.report.update({where:{id},data:{status:b.status}});}
 @Get('settings')settings(){return this.p.appSetting.findMany({orderBy:{key:'asc'}});}
 @Patch('settings/:key')setting(@Param('key')key:string,@Body()b:{value:unknown;public?:boolean}){return this.p.appSetting.upsert({where:{key},create:{key,value:b.value as any,public:b.public??false},update:{value:b.value as any,public:b.public}});}
}
