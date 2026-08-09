"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuditInterceptor = void 0;
const common_1 = require("@nestjs/common");
const operators_1 = require("rxjs/operators");
const audit_service_1 = require("../audit.service");
const audit_event_enum_1 = require("../enums/audit-event.enum");
let AuditInterceptor = class AuditInterceptor {
    auditService;
    constructor(auditService) {
        this.auditService = auditService;
    }
    intercept(context, next) {
        const request = context.switchToHttp().getRequest();
        const { method, path, ip } = request;
        return next.handle().pipe((0, operators_1.tap)({
            next: () => {
                const user = request.user;
                const userId = user ? user.userId : null;
                const response = context.switchToHttp().getResponse();
                this.auditService
                    .logEvent(userId, audit_event_enum_1.AuditEventType.API_REQUEST, 'HttpRequest', path, {
                    method,
                    path,
                    statusCode: response.statusCode,
                    ipAddress: ip,
                }, ip)
                    .catch(() => { });
            },
            error: (err) => {
                const user = request.user;
                const userId = user ? user.userId : null;
                this.auditService
                    .logEvent(userId, audit_event_enum_1.AuditEventType.API_REQUEST, 'HttpRequest', path, {
                    method,
                    path,
                    statusCode: err.status || 500,
                    error: err.message,
                    ipAddress: ip,
                }, ip)
                    .catch(() => { });
            },
        }));
    }
};
exports.AuditInterceptor = AuditInterceptor;
exports.AuditInterceptor = AuditInterceptor = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [audit_service_1.AuditService])
], AuditInterceptor);
//# sourceMappingURL=audit.interceptor.js.map