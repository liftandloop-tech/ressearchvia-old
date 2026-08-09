import { SignalsService } from './signals.service';
import { Segment, Side, OrderType } from '@prisma/client';
export declare class PublishSignalDto {
    segmentId: string;
    symbol: string;
    exchange: string;
    segment: Segment;
    side: Side;
    orderType: OrderType;
    entryPrice: number;
    stopLoss: number;
    targetPrice: number;
}
export declare class SignalsController {
    private readonly signalsService;
    constructor(signalsService: SignalsService);
    publishSignal(dto: PublishSignalDto): Promise<{
        success: boolean;
        signalId: string;
    }>;
}
