import { Injectable, OnModuleInit, Logger, Optional } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class InstrumentsService implements OnModuleInit {
  private readonly logger = new Logger(InstrumentsService.name);
  private instruments: any[] = [];
  private isLoaded = false;

  // AngelOneService injected lazily to avoid circular dependency
  // Injected externally via InstrumentsModule after BrokersModule is loaded
  private angelOneService: any = null;

  setAngelOneService(service: any) {
    this.angelOneService = service;
  }

  async onModuleInit() {
    this.loadInstruments();
  }

  async loadInstruments() {
    try {
      this.logger.log('Downloading Angel One instruments list...');
      const response = await axios.get(
        'https://margincalculator.angelbroking.com/OpenAPI_File/files/OpenAPIScripMaster.json',
        { timeout: 30000 },
      );
      if (Array.isArray(response.data)) {
        this.instruments = response.data;
        this.isLoaded = true;
        this.logger.log(
          `Loaded ${this.instruments.length} instruments successfully.`,
        );
      } else {
        this.logger.error('Invalid response format from Angel One scrip master');
      }
    } catch (err) {
      this.logger.error(`Failed to load instruments list: ${err.message}`);
    }
  }

  search(query: string, exchange?: string): any[] {
    if (!this.isLoaded) return [];
    const normalizedQuery = query.toLowerCase().trim();
    if (!normalizedQuery) return [];

    return this.instruments
      .filter((inst) => {
        const matchesQuery =
          (inst.symbol && inst.symbol.toLowerCase().includes(normalizedQuery)) ||
          (inst.name && inst.name.toLowerCase().includes(normalizedQuery));
        const matchesExchange = exchange
          ? inst.exch_seg === exchange.toUpperCase()
          : true;
        return matchesQuery && matchesExchange;
      })
      .slice(0, 50); // Limit to 50 results for performance
  }

  findToken(symbol: string, exchange: string): string | null {
    if (!this.isLoaded) return null;
    const inst = this.instruments.find(
      (i) => i.symbol === symbol && i.exch_seg === exchange.toUpperCase(),
    );
    return inst ? inst.token : null;
  }

  async getLtp(symbol: string, exchange: string, symbolToken?: string): Promise<any> {
    if (!this.angelOneService) {
      this.logger.warn('AngelOneService not available for LTP fetch');
      return { error: 'Market data service not ready' };
    }

    const resolvedToken = symbolToken || this.findToken(symbol, exchange) || '';
    const result = await this.angelOneService.getLtp(exchange, symbol, undefined, resolvedToken);

    if (!result) {
      return { error: 'Could not fetch LTP. Symbol may not exist or market is closed.' };
    }

    return {
      symbol,
      exchange,
      token: resolvedToken,
      ...result,
    };
  }
}
