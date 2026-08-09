import { InstrumentsService } from './instruments.service';
export declare class InstrumentsController {
    private readonly instrumentsService;
    constructor(instrumentsService: InstrumentsService);
    search(query: string, exchange?: string): any[];
    getLtp(symbol: string, exchange: string, symbolToken?: string): Promise<any>;
}
