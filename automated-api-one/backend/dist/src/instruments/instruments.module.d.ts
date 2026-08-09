import { InstrumentsService } from './instruments.service';
import { AngelOneService } from '../brokers/providers/angel-one.service';
export declare class InstrumentsModule {
    private readonly instrumentsService;
    private readonly angelOneService;
    constructor(instrumentsService: InstrumentsService, angelOneService: AngelOneService);
}
