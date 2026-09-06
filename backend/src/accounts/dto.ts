import { IsBoolean, IsInt, IsNumber, IsOptional, IsPhoneNumber, IsString, IsUUID, IsUrl, Length, Min } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional() @IsString() @Length(2, 80) name?: string;
  @IsOptional() @IsPhoneNumber('EG') phone?: string;
  @IsOptional() @IsString() avatarUrl?: string;
}

export class CreateAddressDto {
  @IsString() @Length(1, 40) label: string;
  @IsString() @Length(2, 80) recipientName: string;
  @IsString() @Length(8, 20) phone: string;
  @IsString() @Length(5, 300) addressLine: string;
  @IsUUID() cityId: string;
  @IsOptional() @IsUUID() areaId?: string;
  @IsOptional() @IsUUID() villageId?: string;
  @IsOptional() @IsBoolean() isDefault?: boolean;
}

export class UpsertStoreDto {
  @IsString() @Length(2, 120) name: string;
  @IsOptional() @IsString() @Length(2, 1000) description?: string;
  @IsUUID() categoryId: string;
  @IsUUID() cityId: string;
  @IsOptional() @IsUUID() areaId?: string;
  @IsOptional() @IsUUID() villageId?: string;
  @IsString() @Length(5, 300) address: string;
  @IsString() @Length(8, 20) phone: string;
  @IsOptional() @IsString() @Length(8, 20) whatsapp?: string;
  @IsOptional() @IsUrl({ require_protocol: true }) logoUrl?: string;
  @IsOptional() @IsUrl({ require_protocol: true }) coverUrl?: string;
  @IsOptional() @IsNumber() latitude?: number;
  @IsOptional() @IsNumber() longitude?: number;
  @IsOptional() @IsBoolean() deliveryEnabled?: boolean;
  @IsOptional() @IsBoolean() pickupEnabled?: boolean;
  @IsOptional() @IsInt() @Min(0) minimumOrderPiasters?: number;
  @IsOptional() @IsInt() @Min(0) deliveryFeePiasters?: number;
}

export class RiderAvailabilityDto { @IsBoolean() available: boolean; }
