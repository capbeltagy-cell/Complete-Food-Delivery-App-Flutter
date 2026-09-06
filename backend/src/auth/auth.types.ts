import { SetMetadata } from '@nestjs/common';
import { Role } from '@prisma/client';
export type JwtUser = { sub: string; role: Role; sessionId: string };
export const ROLES_KEY = 'roles';
export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);
