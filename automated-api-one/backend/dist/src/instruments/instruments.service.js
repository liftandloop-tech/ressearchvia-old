"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var InstrumentsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.InstrumentsService = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = __importDefault(require("axios"));
let InstrumentsService = InstrumentsService_1 = class InstrumentsService {
    logger = new common_1.Logger(InstrumentsService_1.name);
    instruments = [];
    isLoaded = false;
    angelOneService = null;
    setAngelOneService(service) {
        this.angelOneService = service;
    }
    async onModuleInit() {
        this.loadInstruments();
    }
    async loadInstruments() {
        try {
            this.logger.log('Downloading Angel One instruments list...');
            const response = await axios_1.default.get('https://margincalculator.angelbroking.com/OpenAPI_File/files/OpenAPIScripMaster.json', { timeout: 30000 });
            if (Array.isArray(response.data)) {
                this.instruments = response.data;
                this.isLoaded = true;
                this.logger.log(`Loaded ${this.instruments.length} instruments successfully.`);
            }
            else {
                this.logger.error('Invalid response format from Angel One scrip master');
            }
        }
        catch (err) {
            this.logger.error(`Failed to load instruments list: ${err.message}`);
        }
    }
    search(query, exchange) {
        if (!this.isLoaded)
            return [];
        const normalizedQuery = query.toLowerCase().trim();
        if (!normalizedQuery)
            return [];
        return this.instruments
            .filter((inst) => {
            const matchesQuery = (inst.symbol && inst.symbol.toLowerCase().includes(normalizedQuery)) ||
                (inst.name && inst.name.toLowerCase().includes(normalizedQuery));
            const matchesExchange = exchange
                ? inst.exch_seg === exchange.toUpperCase()
                : true;
            return matchesQuery && matchesExchange;
        })
            .slice(0, 50);
    }
    findToken(symbol, exchange) {
        if (!this.isLoaded)
            return null;
        const inst = this.instruments.find((i) => i.symbol === symbol && i.exch_seg === exchange.toUpperCase());
        return inst ? inst.token : null;
    }
    async getLtp(symbol, exchange, symbolToken) {
        if (!this.angelOneService) {
            this.logger.warn('AngelOneService not available for LTP fetch');
            return { error: 'Market data service not ready' };
        }
        const resolvedToken = symbolToken || this.findToken(symbol, exchange) || '';
        const result = await this.angelOneService.getLtp(exchange, symbol, undefined, resolvedToken);
        if (!result) {
            return { error: 'Could not fetch LTP. Symbol may not exist or market is closed.' };
        }
        return {
            symbol,
            exchange,
            token: resolvedToken,
            ...result,
        };
    }
};
exports.InstrumentsService = InstrumentsService;
exports.InstrumentsService = InstrumentsService = InstrumentsService_1 = __decorate([
    (0, common_1.Injectable)()
], InstrumentsService);
//# sourceMappingURL=instruments.service.js.map