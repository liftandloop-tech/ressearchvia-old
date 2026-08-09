import { PrismaService } from '../prisma.service';
import { User, UserDevice } from '@prisma/client';
export declare class UsersService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    findByMobile(mobile: string): Promise<User | null>;
    findById(id: string): Promise<User | null>;
    createOrUpdateUser(mobile: string): Promise<User>;
    updateMpin(userId: string, mpinHash: string): Promise<User>;
    findDevice(userId: string, deviceId: string): Promise<UserDevice | null>;
    trackDevice(userId: string, deviceId: string, deviceName?: string, platform?: string): Promise<UserDevice>;
}
