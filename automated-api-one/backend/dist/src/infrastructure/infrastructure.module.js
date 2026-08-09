"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.InfrastructureModule = void 0;
const common_1 = require("@nestjs/common");
const redis_module_1 = require("./redis/redis.module");
const cache_module_1 = require("./cache/cache.module");
const locks_module_1 = require("./locks/locks.module");
const idempotency_module_1 = require("./idempotency/idempotency.module");
const queues_module_1 = require("./queues/queues.module");
const outbox_module_1 = require("./outbox/outbox.module");
const circuit_breaker_module_1 = require("./circuit-breaker/circuit-breaker.module");
const metrics_module_1 = require("./metrics/metrics.module");
let InfrastructureModule = class InfrastructureModule {
};
exports.InfrastructureModule = InfrastructureModule;
exports.InfrastructureModule = InfrastructureModule = __decorate([
    (0, common_1.Module)({
        imports: [
            redis_module_1.RedisModule,
            cache_module_1.CacheModule,
            locks_module_1.LocksModule,
            idempotency_module_1.IdempotencyModule,
            queues_module_1.QueuesModule,
            outbox_module_1.OutboxModule,
            circuit_breaker_module_1.CircuitBreakerModule,
            metrics_module_1.MetricsModule,
        ],
        exports: [
            redis_module_1.RedisModule,
            cache_module_1.CacheModule,
            locks_module_1.LocksModule,
            idempotency_module_1.IdempotencyModule,
            queues_module_1.QueuesModule,
            outbox_module_1.OutboxModule,
            circuit_breaker_module_1.CircuitBreakerModule,
            metrics_module_1.MetricsModule,
        ],
    })
], InfrastructureModule);
//# sourceMappingURL=infrastructure.module.js.map