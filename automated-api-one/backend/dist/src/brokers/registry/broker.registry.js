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
exports.BrokerRegistry = void 0;
const common_1 = require("@nestjs/common");
const broker_type_enum_1 = require("../interfaces/broker-type.enum");
const angel_one_service_1 = require("../providers/angel-one.service");
const zebu_service_1 = require("../providers/zebu.service");
let BrokerRegistry = class BrokerRegistry {
    angelOne;
    zebu;
    adapters = new Map();
    constructor(angelOne, zebu) {
        this.angelOne = angelOne;
        this.zebu = zebu;
    }
    onModuleInit() {
        this.register(broker_type_enum_1.BrokerType.ANGEL_ONE, this.angelOne);
        this.register(broker_type_enum_1.BrokerType.ZEBU, this.zebu);
    }
    register(type, adapter) {
        this.adapters.set(type, adapter);
    }
    get(type) {
        return this.adapters.get(type);
    }
    has(type) {
        return this.adapters.has(type);
    }
};
exports.BrokerRegistry = BrokerRegistry;
exports.BrokerRegistry = BrokerRegistry = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [angel_one_service_1.AngelOneService,
        zebu_service_1.ZebuService])
], BrokerRegistry);
//# sourceMappingURL=broker.registry.js.map