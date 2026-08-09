import { OnModuleInit } from '@nestjs/common';
export declare class InstrumentsService implements OnModuleInit {
    private readonly logger;
    private instruments;
    private isLoaded;
    private angelOneService;
    setAngelOneService(service: any): void;
    onModuleInit(): Promise<void>;
    loadInstruments(): Promise<void>;
    search(query: string, exchange?: string): any[];
    findToken(symbol: string, exchange: string): string | null;
    getLtp(symbol: string, exchange: string, symbolToken?: string): Promise<any>;
}
