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

  findInstrument(symbol: string, exchange: string): { token: string; symbol: string } | null {
    if (!this.isLoaded || !symbol) return null;
    const upperSymbol = symbol.trim().toUpperCase();
    const upperExchange = (exchange || 'NSE').trim().toUpperCase();

    // 1. Direct exact symbol match (e.g. "SBIN-EQ", "NIFTY24OCT24000CE")
    let inst = this.instruments.find(
      (i) => i.symbol?.toUpperCase() === upperSymbol && i.exch_seg === upperExchange,
    );
    if (inst) {
      return { token: inst.token, symbol: inst.symbol };
    }

    // 2. Cash equity segment suffix match (e.g. query "SBIN" -> matches "SBIN-EQ" on NSE or BSE)
    if (upperExchange === 'NSE' || upperExchange === 'BSE') {
      const eqSymbol = `${upperSymbol}-EQ`;
      inst = this.instruments.find(
        (i) => i.symbol?.toUpperCase() === eqSymbol && i.exch_seg === upperExchange,
      );
      if (inst) {
        return { token: inst.token, symbol: inst.symbol };
      }

      // Check by name if symbol has -EQ
      inst = this.instruments.find(
        (i) => i.name?.toUpperCase() === upperSymbol && i.exch_seg === upperExchange && i.symbol?.endsWith('-EQ'),
      );
      if (inst) {
        return { token: inst.token, symbol: inst.symbol };
      }
    }

    // 3. Fallback: match by name
    inst = this.instruments.find(
      (i) => i.name?.toUpperCase() === upperSymbol && i.exch_seg === upperExchange,
    );
    if (inst) {
      return { token: inst.token, symbol: inst.symbol };
    }

    return null;
  }

  findToken(symbol: string, exchange: string): string | null {
    const inst = this.findInstrument(symbol, exchange);
    return inst ? inst.token : null;
  }

  async getLtp(symbol: string, exchange: string, symbolToken?: string): Promise<any> {
    if (!this.angelOneService) {
      this.logger.warn('AngelOneService not available for LTP fetch');
      return { error: 'Market data service not ready' };
    }

    const resolvedInst = this.findInstrument(symbol, exchange);
    const resolvedToken = symbolToken || resolvedInst?.token || '';
    const tradingSymbol = resolvedInst?.symbol || symbol;
    const result = await this.angelOneService.getLtp(exchange, tradingSymbol, undefined, resolvedToken);

    if (!result) {
      return { error: 'Could not fetch LTP. Symbol may not exist or market is closed.' };
    }

    return {
      symbol: tradingSymbol,
      exchange,
      token: resolvedToken,
      ...result,
    };
  }
}
