import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAddressDto, UpdateProfileDto } from './dto';

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
}
