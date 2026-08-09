import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { InstrumentsService } from './instruments.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('instruments')
@UseGuards(JwtAuthGuard)
export class InstrumentsController {
  constructor(private readonly instrumentsService: InstrumentsService) {}

  @Get()
  search(
    @Query('search') query: string,
    @Query('exchange') exchange?: string,
  ) {
    return this.instrumentsService.search(query || '', exchange);
  }

  /**
   * GET /instruments/ltp?symbol=SBIN-EQ&exchange=NSE&token=3045
   * Returns the Last Traded Price (LTP) and OHLC data for the given symbol.
   * The `token` parameter is the instrument's symbolToken (optional if symbol+exchange is enough to resolve).
   */
  @Get('ltp')
  async getLtp(
    @Query('symbol') symbol: string,
    @Query('exchange') exchange: string,
    @Query('token') symbolToken?: string,
  ) {
    return this.instrumentsService.getLtp(symbol, exchange, symbolToken);
  }
}
