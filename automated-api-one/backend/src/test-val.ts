import { validate } from 'class-validator';
import { LinkBrokerDto } from './brokers/brokers.controller';
import { BrokerCode } from '@prisma/client';

async function main() {
  const dto = new LinkBrokerDto();
  dto.brokerCode = 'ANGEL_ONE' as BrokerCode;
  dto.brokerClientId = 'M320967';

  const errors = await validate(dto);
  if (errors.length > 0) {
    console.log('Validation failed:', errors);
  } else {
    console.log('Validation succeeded!');
  }
}

main();
