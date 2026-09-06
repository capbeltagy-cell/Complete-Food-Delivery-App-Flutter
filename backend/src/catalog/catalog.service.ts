import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductDto } from './dto';
@Injectable() export class CatalogService {
 constructor(private readonly prisma:PrismaService){}
 cities(){return this.prisma.city.findMany({where:{active:true},include:{areas:{where:{active:true},include:{villages:{where:{active:true}}}}},orderBy:{nameAr:'asc'}});}
 categories(){return this.prisma.category.findMany({where:{active:true},orderBy:{sortOrder:'asc'}});}
 stores(cityId?:string,categoryId?:string){return this.prisma.store.findMany({where:{status:'approved',deletedAt:null,...(cityId&&{cityId}),...(categoryId&&{categoryId})},include:{category:true},take:50,orderBy:[{featured:'desc'},{rating:'desc'}]});}
 async store(id:string){const store=await this.prisma.store.findFirst({where:{id,status:'approved',deletedAt:null},include:{category:true,products:{where:{available:true,deletedAt:null},include:{images:{orderBy:{sortOrder:'asc'}}}}}});if(!store)throw new NotFoundException();return store;}
 async createProduct(userId:string,dto:CreateProductDto){await this.assertOwner(userId,dto.storeId);const{imageUrls,...data}=dto;return this.prisma.product.create({data:{...data,available:dto.available??true,images:imageUrls?.length?{create:imageUrls.map((url,sortOrder)=>({url,sortOrder}))}:undefined},include:{images:true}});}
 async updateProduct(userId:string,id:string,dto:Partial<CreateProductDto>){const p=await this.prisma.product.findUnique({where:{id}});if(!p)throw new NotFoundException();await this.assertOwner(userId,p.storeId);const {storeId:_,imageUrls,...data}=dto;return this.prisma.$transaction(async tx=>{if(imageUrls){await tx.productImage.deleteMany({where:{productId:id}});if(imageUrls.length)await tx.productImage.createMany({data:imageUrls.map((url,sortOrder)=>({productId:id,url,sortOrder}))});}return tx.product.update({where:{id},data,include:{images:true}});});}
 async archiveProduct(userId:string,id:string){const p=await this.prisma.product.findUnique({where:{id}});if(!p)throw new NotFoundException();await this.assertOwner(userId,p.storeId);return this.prisma.product.update({where:{id},data:{available:false,deletedAt:new Date()}});}
 async setOpen(userId:string,storeId:string,isOpen:boolean){await this.assertOwner(userId,storeId);return this.prisma.store.update({where:{id:storeId},data:{isOpen}});}
 private async assertOwner(userId:string,storeId:string){const store=await this.prisma.store.findUnique({where:{id:storeId},include:{merchant:true}});if(!store||store.merchant.userId!==userId||store.status!=='approved')throw new ForbiddenException();}
}
