import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';

import { Logger } from 'nestjs-pino';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.enableCors();
  app.useLogger(app.get(Logger));
  app.useGlobalFilters(new HttpExceptionFilter());

  app.use((req: any, res: any, next: any) => {
    if (req.method === 'POST' && req.url.includes('/signals/publish')) {
      console.log('=== INCOMING PUBLISH PAYLOAD ===', JSON.stringify(req.body, null, 2));
    }
    next();
  });

  const config = new DocumentBuilder()
    .setTitle('Trading Strategy Automation Platform API')
    .setDescription('Automated trading strategy APIs and operations')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
