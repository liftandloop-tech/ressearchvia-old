import { PositionsService } from './positions.service';
export declare class ExitPositionDto {
    positionId: string;
}
export declare class PositionsController {
    private readonly positionsService;
    constructor(positionsService: PositionsService);
    getActive(req: any): Promise<{
        symbol: string;
        id: string;
        status: import("@prisma/client").$Enums.PositionStatus;
        realizedPnl: import("@prisma/client-runtime-utils").Decimal;
        unrealizedPnl: import("@prisma/client-runtime-utils").Decimal;
        quantity: number;
        tradeId: string;
        avgPrice: import("@prisma/client-runtime-utils").Decimal;
        currentPrice: import("@prisma/client-runtime-utils").Decimal;
    }[]>;
    exitPosition(req: any, dto: ExitPositionDto): Promise<{
        symbol: string;
        id: string;
        status: import("@prisma/client").$Enums.PositionStatus;
        realizedPnl: import("@prisma/client-runtime-utils").Decimal;
        unrealizedPnl: import("@prisma/client-runtime-utils").Decimal;
        quantity: number;
        tradeId: string;
        avgPrice: import("@prisma/client-runtime-utils").Decimal;
        currentPrice: import("@prisma/client-runtime-utils").Decimal;
    }>;
}
