"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("./app.module");
const common_1 = require("@nestjs/common");
const nestjs_pino_1 = require("nestjs-pino");
const http_exception_filter_1 = require("./common/filters/http-exception.filter");
const swagger_1 = require("@nestjs/swagger");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule, { bufferLogs: true });
    app.enableCors();
    app.useLogger(app.get(nestjs_pino_1.Logger));
    app.useGlobalFilters(new http_exception_filter_1.HttpExceptionFilter());
    app.use((req, res, next) => {
        if (req.method === 'POST' && req.url.includes('/signals/publish')) {
            console.log('=== INCOMING PUBLISH PAYLOAD ===', JSON.stringify(req.body, null, 2));
        }
        next();
    });
    const config = new swagger_1.DocumentBuilder()
        .setTitle('Trading Strategy Automation Platform API')
        .setDescription('Automated trading strategy APIs and operations')
        .setVersion('1.0')
        .addBearerAuth()
        .build();
    const document = swagger_1.SwaggerModule.createDocument(app, config);
    swagger_1.SwaggerModule.setup('api/docs', app, document);
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        transform: true,
    }));
    await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
//# sourceMappingURL=main.js.map