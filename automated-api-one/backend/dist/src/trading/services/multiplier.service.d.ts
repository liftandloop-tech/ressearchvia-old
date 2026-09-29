import { PrismaService } from '../../prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { PositionSizingService } from './position-sizing.service';
export interface MultiplierState {
    index: number;
    current: number;
}
export declare class MultiplierService {
    private readonly prisma;
    private readonly redisService;
    private readonly positionSizingService;
    private readonly logger;
    constructor(prisma: PrismaService, redisService: RedisService, positionSizingService: PositionSizingService);
    getState(userId: string, segmentId: string): Promise<MultiplierState>;
    setState(userId: string, segmentId: string, state: MultiplierState): Promise<void>;
    advanceOnLoss(userId: string, segmentId: string): Promise<MultiplierState>;
    resetOnWin(userId: string, segmentId: string): Promise<void>;
}
