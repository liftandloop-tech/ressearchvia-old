import { Injectable, OnModuleInit } from '@nestjs/common';
import { BrokerAdapter } from '../interfaces/broker-adapter.interface';
import { BrokerType } from '../interfaces/broker-type.enum';
import { AngelOneService } from '../providers/angel-one.service';
import { ZebuService } from '../providers/zebu.service';

@Injectable()
export class BrokerRegistry implements OnModuleInit {
  private readonly adapters = new Map<BrokerType, BrokerAdapter>();

  constructor(
    private readonly angelOne: AngelOneService,
    private readonly zebu: ZebuService,
  ) {}

  onModuleInit() {
    this.register(BrokerType.ANGEL_ONE, this.angelOne);
    this.register(BrokerType.ZEBU, this.zebu);
  }

  register(type: BrokerType, adapter: BrokerAdapter): void {
    this.adapters.set(type, adapter);
  }

  get(type: BrokerType): BrokerAdapter | undefined {
    return this.adapters.get(type);
  }

  has(type: BrokerType): boolean {
    return this.adapters.has(type);
  }
}
