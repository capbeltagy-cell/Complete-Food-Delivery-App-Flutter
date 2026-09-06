import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { Request } from 'express';
import { JwtGuard } from '../auth/jwt.guard';import { JwtUser,Roles } from '../auth/auth.types';import { CatalogService } from './catalog.service';import { CreateProductDto,StoreStateDto } from './dto';
@Controller('catalog') export class CatalogController {constructor(private readonly s:CatalogService){}
 @Get('cities') cities(){return this.s.cities();}
 @Get('categories') categories(){return this.s.categories();}
 @Get('stores') stores(@Query('cityId')cityId?:string,@Query('categoryId')categoryId?:string){return this.s.stores(cityId,categoryId);}
 @Get('stores/:id') store(@Param('id')id:string){return this.s.store(id);}
 @UseGuards(JwtGuard) @Roles(Role.merchant,Role.merchant_staff,Role.admin,Role.super_admin) @Post('products') create(@Req()r:Request&{user:JwtUser},@Body()d:CreateProductDto){return this.s.createProduct(r.user.sub,d);}
 @UseGuards(JwtGuard) @Roles(Role.merchant,Role.merchant_staff,Role.admin,Role.super_admin) @Patch('products/:id') update(@Req()r:Request&{user:JwtUser},@Param('id')id:string,@Body()d:Partial<CreateProductDto>){return this.s.updateProduct(r.user.sub,id,d);}
 @UseGuards(JwtGuard) @Roles(Role.merchant,Role.merchant_staff,Role.admin,Role.super_admin) @Delete('products/:id') remove(@Req()r:Request&{user:JwtUser},@Param('id')id:string){return this.s.archiveProduct(r.user.sub,id);}
 @UseGuards(JwtGuard) @Roles(Role.merchant,Role.admin,Role.super_admin) @Patch('stores/:id/state') state(@Req()r:Request&{user:JwtUser},@Param('id')id:string,@Body()d:StoreStateDto){return this.s.setOpen(r.user.sub,id,d.isOpen);}
}
