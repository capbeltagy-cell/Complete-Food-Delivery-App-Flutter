import { IsBoolean, IsInt, IsOptional, IsString, IsUUID, Length, Min } from 'class-validator';
export class CreateProductDto { @IsUUID() storeId:string; @IsOptional() @IsUUID() categoryId?:string; @IsString() @Length(2,160) name:string; @IsOptional() @IsString() description?:string; @IsInt() @Min(0) pricePiasters:number; @IsOptional() @IsInt() @Min(0) salePricePiasters?:number; @IsOptional() @IsInt() @Min(0) stock?:number; @IsOptional() @IsBoolean() available?:boolean; }
export class StoreStateDto { @IsBoolean() isOpen:boolean; }
