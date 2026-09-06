import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAddressDto, UpdateProfileDto, UpsertStoreDto } from './dto';

@Injectable()
export class AccountsService {
  constructor(private readonly prisma: PrismaService) {}

  async profile(userId: string) {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, active: true, deletedAt: null },
      select: { id: true, email: true, phone: true, role: true, name: true, avatarUrl: true, verifiedAt: true, createdAt: true, merchant: { select: { id: true, status: true, businessName: true, rejectionReason: true } }, rider: { select: { id: true, status: true, available: true } } },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  updateProfile(userId: string, dto: UpdateProfileDto) {
    return this.prisma.user.update({ where: { id: userId }, data: dto, select: { id: true, email: true, phone: true, role: true, name: true, avatarUrl: true, verifiedAt: true, updatedAt: true } });
  }

  addresses(userId: string) {
    return this.prisma.address.findMany({ where: { userId }, orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }] });
  }

  async createAddress(userId: string, dto: CreateAddressDto) {
    return this.prisma.$transaction(async (tx) => {
      if (dto.isDefault) await tx.address.updateMany({ where: { userId, isDefault: true }, data: { isDefault: false } });
      const count = await tx.address.count({ where: { userId } });
      return tx.address.create({ data: { ...dto, userId, isDefault: dto.isDefault ?? count === 0 } });
    });
  }

  async deleteAddress(userId: string, id: string) {
    const result = await this.prisma.address.deleteMany({ where: { id, userId } });
    if (!result.count) throw new NotFoundException('Address not found');
    return { success: true };
  }

  async merchantStore(userId: string) {
    const merchant = await this.prisma.merchant.findUnique({ where: { userId }, include: { stores: { where: { deletedAt: null }, include: { category: true, products: { where: { deletedAt: null }, include: { images: true }, orderBy: { createdAt: 'desc' } } } } } });
    if (!merchant) throw new NotFoundException('Merchant profile not found');
    return { merchant: { id: merchant.id, status: merchant.status, businessName: merchant.businessName, rejectionReason: merchant.rejectionReason }, store: merchant.stores[0] ?? null };
  }

  async createStore(userId: string, dto: UpsertStoreDto) {
    const merchant = await this.prisma.merchant.findUnique({ where: { userId }, include: { stores: { where: { deletedAt: null } } } });
    if (!merchant) throw new ForbiddenException();
    if (merchant.stores.length) throw new ConflictException('Merchant already has a store');
    return this.prisma.store.create({ data: { ...dto, merchantId: merchant.id, status: 'pending' } });
  }

  async updateStore(userId: string, dto: UpsertStoreDto) {
    const merchant = await this.prisma.merchant.findUnique({ where: { userId }, include: { stores: { where: { deletedAt: null }, take: 1 } } });
    if (!merchant?.stores[0]) throw new NotFoundException('Store not found');
    return this.prisma.store.update({ where: { id: merchant.stores[0].id }, data: dto });
  }

  async setRiderAvailability(userId: string, available: boolean) {
    const rider = await this.prisma.rider.findUnique({ where: { userId } });
    if (!rider || rider.status !== 'approved') throw new ForbiddenException('Rider is not approved');
    return this.prisma.rider.update({ where: { id: rider.id }, data: { available } });
  }
}
