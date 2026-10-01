import { Test, TestingModule } from '@nestjs/testing';
import { AppModule } from '../../src/app.module';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { PrismaService } from '../../src/prisma.service';
import { mockPrismaService } from '../mocks/prisma.mock';
import { HttpExceptionFilter } from '../../src/common/filters/http-exception.filter';

process.env.NODE_ENV = 'test';
process.env.DATABASE_URL =
  process.env.DATABASE_URL ||
  'postgresql://postgres:postgrespassword@localhost:5432/trading_platform?schema=public';
process.env.JWT_SECRET =
  process.env.JWT_SECRET || 'super_secret_jwt_key_that_is_at_least_eight_chars';
process.env.JWT_REFRESH_SECRET =
  process.env.JWT_REFRESH_SECRET || 'super_secret_jwt_refresh_key_that_is_long';
process.env.MOCK_BROKERS = 'true';
process.env.REDIS_HOST = process.env.REDIS_HOST || 'localhost';
process.env.REDIS_PORT = process.env.REDIS_PORT || '6379';

export async function createTestApp(): Promise<{
  app: INestApplication;
  prismaMock: any;
}> {
  const prismaMock = mockPrismaService();

  const moduleFixture: TestingModule = await Test.createTestingModule({
    imports: [AppModule],
  })
    .overrideProvider(PrismaService)
    .useValue(prismaMock)
    .compile();

  const app = moduleFixture.createNestApplication();
  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );

  await app.init();

  return { app, prismaMock };
}
