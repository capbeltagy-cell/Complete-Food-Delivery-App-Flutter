import { IsBoolean, IsOptional, IsPhoneNumber, IsString, IsUUID, Length } from 'class-validator';

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
