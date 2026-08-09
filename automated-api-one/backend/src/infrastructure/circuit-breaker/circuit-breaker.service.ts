import { Injectable, Logger } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
import { RedisKeys } from '../redis/redis-keys';
import { ConfigService } from '@nestjs/config';
import { MetricsService } from '../metrics/metrics.service';

export enum CircuitState {
  CLOSED = 'CLOSED',
  OPEN = 'OPEN',
  HALF_OPEN = 'HALF_OPEN',
}

export class BrokerUnavailableException extends Error {
  constructor(message = 'Broker API is currently unavailable (circuit open)') {
    super(message);
    this.name = 'BrokerUnavailableException';
  }
}

@Injectable()
export class CircuitBreakerService {
  private readonly logger = new Logger(CircuitBreakerService.name);
  
  // Local memory fallback in case Redis connection is lost/degraded
  private memStates = new Map<string, { state: CircuitState; failures: number; lastChange: number }>();

  private readonly cooldownMs: number;
  private readonly failureThreshold: number;

  constructor(
    private readonly redisService: RedisService,
    private readonly configService: ConfigService,
    private readonly metrics: MetricsService,
  ) {
    this.cooldownMs = this.configService.get<number>('CIRCUIT_BREAKER_RESET_TIMEOUT_MS', 60000);
    this.failureThreshold = this.configService.get<number>('CIRCUIT_BREAKER_FAILURE_THRESHOLD', 3);
  }

  private setCircuitStateGauge(broker: string, state: CircuitState) {
    let val = 0;
    if (state === CircuitState.CLOSED) val = 0;
    else if (state === CircuitState.HALF_OPEN) val = 1;
    else if (state === CircuitState.OPEN) val = 2;
    this.metrics.setBrokerCircuitState(broker, val);
  }

  private async getCircuitInfo(broker: string): Promise<{ state: CircuitState; failures: number; lastChange: number }> {
    const defaultInfo = { state: CircuitState.CLOSED, failures: 0, lastChange: Date.now() };

    if (!this.redisService.isHealthy()) {
      this.logger.warn(`Redis is unhealthy. Using local memory circuit state for broker: ${broker}`);
      if (!this.memStates.has(broker)) {
        this.memStates.set(broker, defaultInfo);
      }
      return this.memStates.get(broker)!;
    }

    try {
      const redisKey = RedisKeys.circuitBreaker(broker);
      const data = await this.redisService.getClient().get(redisKey);
      if (!data) {
        await this.setCircuitInfo(broker, defaultInfo);
        return defaultInfo;
      }
      return JSON.parse(data);
    } catch (err) {
      this.logger.error(`Failed to read circuit info from Redis: ${err.message}`);
      return this.memStates.get(broker) || defaultInfo;
    }
  }

  private async setCircuitInfo(
    broker: string,
    info: { state: CircuitState; failures: number; lastChange: number },
  ): Promise<void> {
    this.memStates.set(broker, info);
    this.setCircuitStateGauge(broker, info.state);

    if (!this.redisService.isHealthy()) return;

    try {
      const redisKey = RedisKeys.circuitBreaker(broker);
      await this.redisService.getClient().set(redisKey, JSON.stringify(info), 'EX', 86400); // 24 hour expiration
    } catch (err) {
      this.logger.error(`Failed to save circuit info to Redis: ${err.message}`);
    }
  }

  /**
   * Executes an operation protected by the broker circuit breaker.
   */
  async execute<T>(broker: string, operation: () => Promise<T>): Promise<T> {
    const info = await this.getCircuitInfo(broker);
    let state = info.state;
    let lastChange = info.lastChange;

    // Transition from OPEN to HALF_OPEN after cooldown expires
    if (state === CircuitState.OPEN && Date.now() - lastChange >= this.cooldownMs) {
      this.logger.log(`Circuit for broker ${broker} transitioning from OPEN to HALF_OPEN (cooldown expired)`);
      state = CircuitState.HALF_OPEN;
      const duration = Date.now() - lastChange;
      this.metrics.observeBrokerCircuitOpenDuration(broker, duration);
      lastChange = Date.now();
      await this.setCircuitInfo(broker, { ...info, state, lastChange });
    }

    if (state === CircuitState.OPEN) {
      throw new BrokerUnavailableException(`Broker ${broker} API is unavailable (circuit open)`);
    }

    try {
      const result = await operation();
      await this.onSuccess(broker, state, info);
      return result;
    } catch (err) {
      await this.onFailure(broker, state, info, err);
      throw err;
    }
  }

  private async onSuccess(
    broker: string,
    currentState: CircuitState,
    info: { state: CircuitState; failures: number; lastChange: number },
  ) {
    if (currentState === CircuitState.HALF_OPEN) {
      this.logger.log(`Circuit for broker ${broker} is now CLOSED (pilot request succeeded)`);
      await this.setCircuitInfo(broker, {
        state: CircuitState.CLOSED,
        failures: 0,
        lastChange: Date.now(),
      });
    } else if (info.failures > 0) {
      await this.setCircuitInfo(broker, {
        ...info,
        failures: 0,
      });
    }
  }

  private async onFailure(
    broker: string,
    currentState: CircuitState,
    info: { state: CircuitState; failures: number; lastChange: number },
    error: any,
  ) {
    const failures = info.failures + 1;
    this.logger.warn(`Failure recorded for broker ${broker}. Consecutive failures: ${failures}. Error: ${error.message}`);

    if (currentState === CircuitState.HALF_OPEN || failures >= this.failureThreshold) {
      this.logger.error(`Circuit for broker ${broker} is now OPEN. Requests will be blocked for 60 seconds.`);
      this.metrics.incrementBrokerCircuitOpen(broker);
      await this.setCircuitInfo(broker, {
        state: CircuitState.OPEN,
        failures,
        lastChange: Date.now(),
      });
    } else {
      await this.setCircuitInfo(broker, {
        ...info,
        failures,
      });
    }
  }
}
