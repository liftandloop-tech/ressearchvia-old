import { Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { PrismaService } from '../prisma.service';
declare const JwtStrategy_base: new (...args: [opt: import("passport-jwt").StrategyOptionsWithRequest] | [opt: import("passport-jwt").StrategyOptionsWithoutRequest]) => Strategy & {
    validate(...args: any[]): unknown;
};
export declare class JwtStrategy extends JwtStrategy_base {
    private readonly configService;
    private readonly usersService;
    private readonly prisma;
    constructor(configService: ConfigService, usersService: UsersService, prisma: PrismaService);
    validate(payload: {
        sub?: string;
        _id?: string;
        mobile?: string;
        phone?: string;
    }): Promise<{
        userId: any;
        email: any;
        role: any;
        isAdmin: boolean;
        mobile?: undefined;
    } | {
        userId: string;
        mobile: string;
        role: string;
        isAdmin: boolean;
        email?: undefined;
    }>;
}
export {};
