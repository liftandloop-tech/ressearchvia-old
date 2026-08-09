import { Injectable, NotImplementedException } from '@nestjs/common';
import { BrokerRegistry } from '../registry/broker.registry';
import { BrokerAdapter } from '../interfaces/broker-adapter.interface';
import { BrokerType } from '../interfaces/broker-type.enum';

@Injectable()
export class BrokerFactory {
  constructor(private readonly registry: BrokerRegistry) {}

  getAdapter(type: BrokerType): BrokerAdapter {
    if (!this.registry.has(type)) {
      throw new NotImplementedException(`${type} adapter not implemented`);
    }
    const adapter = this.registry.get(type);
    if (!adapter) {
      throw new NotImplementedException(
        `No broker adapter registered for type: ${type}`,
      );
    }
    return adapter;
  }
}
