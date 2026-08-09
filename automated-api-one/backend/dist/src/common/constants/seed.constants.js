"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SEED_USERS = exports.SEED_BROKERS = exports.SEED_SEGMENTS = exports.SEED_PLANS = void 0;
exports.SEED_PLANS = {
    SPARK: {
        id: '11111111-e29b-41d4-a716-446655440001',
        name: 'SPARK',
        durationDays: 30,
    },
    SPLENDID: {
        id: '22222222-e29b-41d4-a716-446655440002',
        name: 'SPLENDID',
        durationDays: 365,
    },
};
exports.SEED_SEGMENTS = {
    EQUITY_CASH: {
        id: '00000000-6990-5827-19e0-550821bb9436',
        name: 'EQUITY CASH',
        description: '',
        segment: 'INTRADAY',
    },
    FUTURE_DERIVATIVES: {
        id: '00000000-6990-5833-19e0-550821bb943b',
        name: 'FUTURE DERIVATIVES',
        description: '',
        segment: 'FO',
    },
    STOCK_OPTION: {
        id: '00000000-6990-5848-19e0-550821bb9447',
        name: 'STOCK OPTION',
        description: '',
        segment: 'FO',
    },
    INDEX_OPTION: {
        id: '00000000-6990-5852-19e0-550821bb945a',
        name: 'INDEX OPTION',
        description: '',
        segment: 'FO',
    },
    MCX_COMMODITY: {
        id: '00000000-6990-5862-19e0-550821bb94bb',
        name: 'MCX COMMODITY',
        description: '',
        segment: 'INTRADAY',
    },
    NCDEX_COMMODITY: {
        id: '00000000-6990-586d-19e0-550821bb94ce',
        name: 'NCDEX COMMODITY',
        description: '',
        segment: 'INTRADAY',
    },
    CURRENCY_DERIVATIVIS: {
        id: '00000000-6990-5880-19e0-550821bb9544',
        name: 'CURRENCY DERIVATIVIS',
        description: '',
        segment: 'INTRADAY',
    },
};
exports.SEED_BROKERS = {
    ANGEL_ONE: {
        id: '44444444-e29b-41d4-a716-446655440001',
        code: 'ANGEL_ONE',
        name: 'Angel One',
    },
    ZERODHA: {
        id: '44444444-e29b-41d4-a716-446655440002',
        code: 'ZERODHA',
        name: 'Zerodha',
    },
    UPSTOX: {
        id: '44444444-e29b-41d4-a716-446655440003',
        code: 'UPSTOX',
        name: 'Upstox',
    },
    FYERS: {
        id: '44444444-e29b-41d4-a716-446655440004',
        code: 'FYERS',
        name: 'Fyers',
    },
    DHAN: {
        id: '44444444-e29b-41d4-a716-446655440005',
        code: 'DHAN',
        name: 'Dhan',
    },
};
exports.SEED_USERS = {
    ADMIN: {
        id: '55555555-e29b-41d4-a716-446655440001',
        email: 'admin@platform.local',
        password: 'Admin@1234',
    },
    ANALYST: {
        id: '55555555-e29b-41d4-a716-446655440002',
        email: 'analyst@platform.local',
        name: 'Default Analyst',
    },
    CLIENT: {
        id: '55555555-e29b-41d4-a716-446655440003',
        email: 'client@platform.local',
        mobile: '0000000000',
        mpin: '123456',
    },
};
//# sourceMappingURL=seed.constants.js.map