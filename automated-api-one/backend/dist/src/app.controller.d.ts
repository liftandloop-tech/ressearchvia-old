import { AppService } from './app.service';
import { PrismaService } from './prisma.service';
import * as express from 'express';
export declare class AppController {
    private readonly appService;
    private readonly prisma;
    constructor(appService: AppService, prisma: PrismaService);
    getHello(): string;
    getHealth(res: express.Response): Promise<express.Response<any, Record<string, any>>>;
}
