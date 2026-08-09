import { Module, forwardRef } from '@nestjs/common';
import { InstrumentsService } from './instruments.service';
import { InstrumentsController } from './instruments.controller';
import { BrokersModule } from '../brokers/brokers.module';
import { AngelOneService } from '../brokers/providers/angel-one.service';

@Module({
  imports: [forwardRef(() => BrokersModule)],
  controllers: [InstrumentsController],
  providers: [InstrumentsService],
  exports: [InstrumentsService],
})
export class InstrumentsModule {
  constructor(
    private readonly instrumentsService: InstrumentsService,
    private readonly angelOneService: AngelOneService,
  ) {
    this.instrumentsService.setAngelOneService(this.angelOneService);
  }
}
