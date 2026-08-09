import { OnModuleInit } from '@nestjs/common';
import { BrokerAdapter } from '../interfaces/broker-adapter.interface';
import { BrokerType } from '../interfaces/broker-type.enum';
import { AngelOneService } from '../providers/angel-one.service';
import { ZebuService } from '../providers/zebu.service';
export declare class BrokerRegistry implements OnModuleInit {
    private readonly angelOne;
    private readonly zebu;
    private readonly adapters;
    constructor(angelOne: AngelOneService, zebu: ZebuService);
    onModuleInit(): void;
    register(type: BrokerType, adapter: BrokerAdapter): void;
    get(type: BrokerType): BrokerAdapter | undefined;
    has(type: BrokerType): boolean;
}
