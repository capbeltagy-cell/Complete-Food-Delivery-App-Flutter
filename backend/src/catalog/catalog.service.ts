import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductDto } from './dto';
@Injectable() export class CatalogService {
 constructor(private readonly prisma:PrismaService){}
 cities(){return this.prisma.city.findMany({where:{active:true},include:{areas:{where:{active:true},include:{villages:{where:{active:true}}}}},orderBy:{nameAr:'asc'}});}
 categories(){return this.prisma.category.findMany({where:{active:true},orderBy:{sortOrder:'asc'}});}
 stores(cityId?:string,categoryId?:string){return this.prisma.store.findMany({where:{status:'approved',deletedAt:null,...(cityId&&{cityId}),...(categoryId&&{categoryId})},include:{category:true},take:50,orderBy:[{featured:'desc'},{rating:'desc'}]});}
 async store(id:string){const store=await this.prisma.store.findFirst({where:{id,status:'approved',deletedAt:null},include:{category:true,products:{where:{available:true,deletedAt:null},include:{images:{orderBy:{sortOrder:'asc'}}}}}});if(!store)throw new NotFoundException();return store;}
 async createProduct(userId:string,dto:CreateProductDto){await this.assertOwner(userId,dto.storeId);const{imageUrls,...data}=dto;const images=await this.ownedImages(userId,imageUrls);return this.prisma.product.create({data:{...data,available:dto.available??true,images:images.length?{create:images}:undefined},include:{images:true}});}
 async updateProduct(userId:string,id:string,dto:Partial<CreateProductDto>){const p=await this.prisma.product.findUnique({where:{id}});if(!p)throw new NotFoundException();await this.assertOwner(userId,p.storeId);const {storeId:_,imageUrls,...data}=dto;const images=await this.ownedImages(userId,imageUrls);return this.prisma.$transaction(async tx=>{if(imageUrls){await tx.productImage.deleteMany({where:{productId:id}});if(images.length)await tx.productImage.createMany({data:images.map(image=>({...image,productId:id}))});}return tx.product.update({where:{id},data,include:{images:true}});});}
 async archiveProduct(userId:string,id:string){const p=await this.prisma.product.findUnique({where:{id}});if(!p)throw new NotFoundException();await this.assertOwner(userId,p.storeId);return this.prisma.product.update({where:{id},data:{available:false,deletedAt:new Date()}});}
 async setOpen(userId:string,storeId:string,isOpen:boolean){await this.assertOwner(userId,storeId);return this.prisma.store.update({where:{id:storeId},data:{isOpen}});}
 private async assertOwner(userId:string,storeId:string){const store=await this.prisma.store.findUnique({where:{id:storeId},include:{merchant:true}});if(!store||store.merchant.userId!==userId||['rejected','suspended'].includes(store.status))throw new ForbiddenException();}
 private async ownedImages(userId:string,urls?:string[]){if(!urls?.length)return[];const uploads=await this.prisma.upload.findMany({where:{ownerId:userId,url:{in:urls},deletedAt:null}});if(uploads.length!==new Set(urls).size)throw new ForbiddenException('Invalid image ownership');return urls.map((url,sortOrder)=>{const upload=uploads.find(item=>item.url===url)!;return{url,storageKey:upload.storageKey,sortOrder};});}
}
