import { Injectable } from '@nestjs/common';
import {
  HealthIndicator,
  HealthIndicatorResult,
  HealthCheckError,
} from '@nestjs/terminus';
import { ConfigService } from '@nestjs/config';
import { BrokerFactory } from '../brokers/factory/broker.factory';
import { BrokerType } from '../brokers/interfaces/broker-type.enum';

@Injectable()
export class BrokerHealthIndicator extends HealthIndicator {
  constructor(
    private readonly configService: ConfigService,
    private readonly brokerFactory: BrokerFactory,
  ) {
    super();
  }

  async getCustomHealth() {
    const start = Date.now();
    const mockVal = this.configService.get<any>('MOCK_BROKERS', true);
    const isMock = mockVal === true || mockVal === 'true';

    if (isMock) {
      return {
        status: 'up',
        broker: 'ANGEL_ONE',
        reachable: true,
        authenticationValid: true,
        responseTimeMs: 10,
        message: 'Mock broker mode is active and healthy',
      };
    }

    try {
      const apiKey = this.configService.get<string>('ANGEL_ONE_API_KEY');
      const authenticationValid = !!apiKey;

      const adapter = this.brokerFactory.getAdapter(BrokerType.ANGEL_ONE);
      const checkResult = await adapter.healthCheck();

      return {
        status: checkResult.reachable && authenticationValid ? 'up' : 'down',
        broker: 'ANGEL_ONE',
        reachable: checkResult.reachable,
        authenticationValid,
        responseTimeMs: checkResult.responseTimeMs,
      };
    } catch (error) {
      return {
        status: 'down',
        broker: 'ANGEL_ONE',
        reachable: false,
        authenticationValid: false,
        responseTimeMs: Date.now() - start,
      };
    }
  }

  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    const custom = await this.getCustomHealth();
    const isHealthy = custom.status === 'up';
    if (isHealthy) {
      return this.getStatus(key, true, custom);
    } else {
      throw new HealthCheckError(
        'Broker check failed',
        this.getStatus(key, false, custom),
      );
    }
  }
}
