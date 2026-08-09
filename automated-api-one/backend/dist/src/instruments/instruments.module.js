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
exports.InstrumentsModule = void 0;
const common_1 = require("@nestjs/common");
const instruments_service_1 = require("./instruments.service");
const instruments_controller_1 = require("./instruments.controller");
const brokers_module_1 = require("../brokers/brokers.module");
const angel_one_service_1 = require("../brokers/providers/angel-one.service");
let InstrumentsModule = class InstrumentsModule {
    instrumentsService;
    angelOneService;
    constructor(instrumentsService, angelOneService) {
        this.instrumentsService = instrumentsService;
        this.angelOneService = angelOneService;
        this.instrumentsService.setAngelOneService(this.angelOneService);
    }
};
exports.InstrumentsModule = InstrumentsModule;
exports.InstrumentsModule = InstrumentsModule = __decorate([
    (0, common_1.Module)({
        imports: [(0, common_1.forwardRef)(() => brokers_module_1.BrokersModule)],
        controllers: [instruments_controller_1.InstrumentsController],
        providers: [instruments_service_1.InstrumentsService],
        exports: [instruments_service_1.InstrumentsService],
    }),
    __metadata("design:paramtypes", [instruments_service_1.InstrumentsService,
        angel_one_service_1.AngelOneService])
], InstrumentsModule);
//# sourceMappingURL=instruments.module.js.map