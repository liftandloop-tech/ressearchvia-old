import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';
import { Prisma } from '@prisma/client';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';
    let errorCode = 'INTERNAL_SERVER_ERROR';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse() as any;

      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        // Validation errors usually return message as array or string
        message = Array.isArray(exceptionResponse.message)
          ? exceptionResponse.message.join(', ')
          : exceptionResponse.message || exception.message;

        errorCode = exceptionResponse.error
          ? exceptionResponse.error.toUpperCase().replace(/\s+/g, '_')
          : 'HTTP_ERROR';
      } else {
        message = exceptionResponse || exception.message;
      }
    } else if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      status = HttpStatus.CONFLICT;
      message = `Database transaction failed: ${exception.message}`;
      errorCode = `DB_ERROR_${exception.code}`;

      if (exception.code === 'P2002') {
        status = HttpStatus.BAD_REQUEST;
        const targets = (exception.meta?.target as string[]) || [];
        message = `Unique constraint violation on field(s): ${targets.join(', ')}`;
        errorCode = 'UNIQUE_CONSTRAINT_VIOLATION';
      } else if (exception.code === 'P2025') {
        status = HttpStatus.NOT_FOUND;
        message = 'The requested database record was not found.';
        errorCode = 'RECORD_NOT_FOUND';
      }
    } else if (exception instanceof Error) {
      message = exception.message;
      this.logger.error(
        `Unhandled error: ${exception.message}`,
        exception.stack,
      );
    } else {
      this.logger.error(`Unknown error caught: ${JSON.stringify(exception)}`);
    }

    // Specialize error codes for common status levels
    if (status === HttpStatus.BAD_REQUEST && errorCode === 'HTTP_ERROR') {
      errorCode = 'BAD_REQUEST';
    } else if (status === HttpStatus.UNAUTHORIZED) {
      errorCode = 'UNAUTHORIZED';
    } else if (status === HttpStatus.FORBIDDEN) {
      errorCode = 'FORBIDDEN';
    } else if (status === HttpStatus.NOT_FOUND) {
      errorCode = 'NOT_FOUND';
    }

    response.status(status).json({
      success: false,
      message,
      errorCode,
    });
  }
}
