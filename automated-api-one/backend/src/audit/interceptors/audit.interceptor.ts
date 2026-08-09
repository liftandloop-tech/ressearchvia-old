import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { AuditService } from '../audit.service';
import { AuditEventType } from '../enums/audit-event.enum';

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private readonly auditService: AuditService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, path, ip } = request;

    return next.handle().pipe(
      tap({
        next: () => {
          const user = request.user;
          const userId = user ? user.userId : null;
          const response = context.switchToHttp().getResponse();

          this.auditService
            .logEvent(
              userId,
              AuditEventType.API_REQUEST,
              'HttpRequest',
              path,
              {
                method,
                path,
                statusCode: response.statusCode,
                ipAddress: ip,
              },
              ip,
            )
            .catch(() => {}); // Suppress background logging errors
        },
        error: (err) => {
          const user = request.user;
          const userId = user ? user.userId : null;

          this.auditService
            .logEvent(
              userId,
              AuditEventType.API_REQUEST,
              'HttpRequest',
              path,
              {
                method,
                path,
                statusCode: err.status || 500,
                error: err.message,
                ipAddress: ip,
              },
              ip,
            )
            .catch(() => {});
        },
      }),
    );
  }
}
