"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var HttpExceptionFilter_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.HttpExceptionFilter = void 0;
const common_1 = require("@nestjs/common");
const client_1 = require("@prisma/client");
let HttpExceptionFilter = HttpExceptionFilter_1 = class HttpExceptionFilter {
    logger = new common_1.Logger(HttpExceptionFilter_1.name);
    catch(exception, host) {
        const ctx = host.switchToHttp();
        const response = ctx.getResponse();
        let status = common_1.HttpStatus.INTERNAL_SERVER_ERROR;
        let message = 'Internal server error';
        let errorCode = 'INTERNAL_SERVER_ERROR';
        if (exception instanceof common_1.HttpException) {
            status = exception.getStatus();
            const exceptionResponse = exception.getResponse();
            if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
                message = Array.isArray(exceptionResponse.message)
                    ? exceptionResponse.message.join(', ')
                    : exceptionResponse.message || exception.message;
                errorCode = exceptionResponse.error
                    ? exceptionResponse.error.toUpperCase().replace(/\s+/g, '_')
                    : 'HTTP_ERROR';
            }
            else {
                message = exceptionResponse || exception.message;
            }
        }
        else if (exception instanceof client_1.Prisma.PrismaClientKnownRequestError) {
            status = common_1.HttpStatus.CONFLICT;
            message = `Database transaction failed: ${exception.message}`;
            errorCode = `DB_ERROR_${exception.code}`;
            if (exception.code === 'P2002') {
                status = common_1.HttpStatus.BAD_REQUEST;
                const targets = exception.meta?.target || [];
                message = `Unique constraint violation on field(s): ${targets.join(', ')}`;
                errorCode = 'UNIQUE_CONSTRAINT_VIOLATION';
            }
            else if (exception.code === 'P2025') {
                status = common_1.HttpStatus.NOT_FOUND;
                message = 'The requested database record was not found.';
                errorCode = 'RECORD_NOT_FOUND';
            }
        }
        else if (exception instanceof Error) {
            message = exception.message;
            this.logger.error(`Unhandled error: ${exception.message}`, exception.stack);
        }
        else {
            this.logger.error(`Unknown error caught: ${JSON.stringify(exception)}`);
        }
        if (status === common_1.HttpStatus.BAD_REQUEST && errorCode === 'HTTP_ERROR') {
            errorCode = 'BAD_REQUEST';
        }
        else if (status === common_1.HttpStatus.UNAUTHORIZED) {
            errorCode = 'UNAUTHORIZED';
        }
        else if (status === common_1.HttpStatus.FORBIDDEN) {
            errorCode = 'FORBIDDEN';
        }
        else if (status === common_1.HttpStatus.NOT_FOUND) {
            errorCode = 'NOT_FOUND';
        }
        response.status(status).json({
            success: false,
            message,
            errorCode,
        });
    }
};
exports.HttpExceptionFilter = HttpExceptionFilter;
exports.HttpExceptionFilter = HttpExceptionFilter = HttpExceptionFilter_1 = __decorate([
    (0, common_1.Catch)()
], HttpExceptionFilter);
//# sourceMappingURL=http-exception.filter.js.map