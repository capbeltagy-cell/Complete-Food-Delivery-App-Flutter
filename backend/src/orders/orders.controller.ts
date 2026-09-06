import{Body,Controller,Get,Param,Patch,Post,Req,UseGuards}from'@nestjs/common';import{Role}from'@prisma/client';import{Request}from'express';import{JwtGuard}from'../auth/jwt.guard';import{JwtUser,Roles}from'../auth/auth.types';import{CreateOrderDto,TransitionOrderDto}from'./dto';import{OrdersService}from'./orders.service';
@UseGuards(JwtGuard)@Controller('orders')export class OrdersController{constructor(private readonly s:OrdersService){}
 @Roles(Role.customer)@Post()create(@Req()r:Request&{user:JwtUser},@Body()d:CreateOrderDto){return this.s.create(r.user.sub,d);}
 @Get()list(@Req()r:Request&{user:JwtUser}){return this.s.list(r.user.sub,r.user.role);}
 @Roles(Role.rider)@Get('available')available(@Req()r:Request&{user:JwtUser}){return this.s.available(r.user.sub);}
 @Roles(Role.rider)@Post(':id/claim')claim(@Req()r:Request&{user:JwtUser},@Param('id')id:string){return this.s.claim(id,r.user.sub);}
 @Patch(':id/status')transition(@Req()r:Request&{user:JwtUser},@Param('id')id:string,@Body()d:TransitionOrderDto){return this.s.transition(id,r.user.sub,r.user.role,d.status,d.note);}
}
