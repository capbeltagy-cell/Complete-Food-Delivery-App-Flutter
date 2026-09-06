import { Body, Controller, Delete, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { JwtGuard } from '../auth/jwt.guard';
import { JwtUser } from '../auth/auth.types';
import { AccountsService } from './accounts.service';
import { Role } from '@prisma/client';
import { Roles } from '../auth/auth.types';
import { CreateAddressDto, RiderAvailabilityDto, UpdateProfileDto, UpsertStoreDto } from './dto';

@UseGuards(JwtGuard)
@Controller('account')
export class AccountsController {
  constructor(private readonly service: AccountsService) {}
  @Get() profile(@Req() req: Request & { user: JwtUser }) { return this.service.profile(req.user.sub); }
  @Patch() update(@Req() req: Request & { user: JwtUser }, @Body() dto: UpdateProfileDto) { return this.service.updateProfile(req.user.sub, dto); }
  @Get('addresses') addresses(@Req() req: Request & { user: JwtUser }) { return this.service.addresses(req.user.sub); }
  @Post('addresses') createAddress(@Req() req: Request & { user: JwtUser }, @Body() dto: CreateAddressDto) { return this.service.createAddress(req.user.sub, dto); }
  @Delete('addresses/:id') deleteAddress(@Req() req: Request & { user: JwtUser }, @Param('id') id: string) { return this.service.deleteAddress(req.user.sub, id); }
  @Roles(Role.merchant) @Get('merchant/store') merchantStore(@Req() req: Request & { user: JwtUser }) { return this.service.merchantStore(req.user.sub); }
  @Roles(Role.merchant) @Post('merchant/store') createStore(@Req() req: Request & { user: JwtUser }, @Body() dto: UpsertStoreDto) { return this.service.createStore(req.user.sub, dto); }
  @Roles(Role.merchant) @Patch('merchant/store') updateStore(@Req() req: Request & { user: JwtUser }, @Body() dto: UpsertStoreDto) { return this.service.updateStore(req.user.sub, dto); }
  @Roles(Role.rider) @Patch('rider/availability') availability(@Req() req: Request & { user: JwtUser }, @Body() dto: RiderAvailabilityDto) { return this.service.setRiderAvailability(req.user.sub, dto.available); }
}
