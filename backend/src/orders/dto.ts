import { IsArray, IsEnum, IsInt, IsObject, IsOptional, IsString, IsUUID, Length, Min, ValidateNested } from 'class-validator';import{Type}from'class-transformer';import{OrderStatus}from'@prisma/client';
export class OrderLineDto{@IsUUID()productId:string;@IsInt()@Min(1)quantity:number;}
export class CreateOrderDto{@IsUUID()storeId:string;@IsArray()@ValidateNested({each:true})@Type(()=>OrderLineDto)items:OrderLineDto[];@IsString()@Length(2,100)customerName:string;@IsString()@Length(8,20)customerPhone:string;@IsObject()deliveryAddress:Record<string,unknown>;@IsOptional()@IsString()notes?:string;}
export class TransitionOrderDto{@IsEnum(OrderStatus)status:OrderStatus;@IsOptional()@IsString()note?:string;}
