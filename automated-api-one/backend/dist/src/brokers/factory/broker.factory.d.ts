import { BrokerRegistry } from '../registry/broker.registry';
import { BrokerAdapter } from '../interfaces/broker-adapter.interface';
import { BrokerType } from '../interfaces/broker-type.enum';
export declare class BrokerFactory {
    private readonly registry;
    constructor(registry: BrokerRegistry);
    getAdapter(type: BrokerType): BrokerAdapter;
}
