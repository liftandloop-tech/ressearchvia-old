"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.seed = seed;
const client_1 = require("@prisma/client");
const bcrypt = __importStar(require("bcrypt"));
const seed_constants_1 = require("../src/common/constants/seed.constants");
let prismaInstance = null;
async function seed(client) {
    const db = client || prismaInstance || (prismaInstance = new client_1.PrismaClient());
    const brokersToSeed = Object.values(seed_constants_1.SEED_BROKERS);
    for (const broker of brokersToSeed) {
        await db.broker.upsert({
            where: { id: broker.id },
            update: {
                code: broker.code,
                name: broker.name,
                status: client_1.BrokerStatus.ACTIVE,
            },
            create: {
                id: broker.id,
                code: broker.code,
                name: broker.name,
                status: client_1.BrokerStatus.ACTIVE,
            },
        });
    }
    const segmentsToSeed = Object.values(seed_constants_1.SEED_SEGMENTS).map((seg) => ({
        id: seg.id,
        name: seg.name,
        description: seg.description,
        segment: seg.segment,
        status: client_1.UserSegmentStatus.ACTIVE,
    }));
    for (const segment of segmentsToSeed) {
        await db.segmentMaster.upsert({
            where: { id: segment.id },
            update: {
                name: segment.name,
                description: segment.description,
                segment: segment.segment,
                status: segment.status,
            },
            create: segment,
        });
    }
    const adminData = seed_constants_1.SEED_USERS.ADMIN;
    const adminPasswordHash = await bcrypt.hash(adminData.password, 10);
    await db.adminUser.upsert({
        where: { id: adminData.id },
        update: {
            email: adminData.email,
            passwordHash: adminPasswordHash,
            role: client_1.AdminRole.ADMIN,
            status: client_1.AdminStatus.ACTIVE,
        },
        create: {
            id: adminData.id,
            email: adminData.email,
            passwordHash: adminPasswordHash,
            role: client_1.AdminRole.ADMIN,
            status: client_1.AdminStatus.ACTIVE,
        },
    });
    const analystData = seed_constants_1.SEED_USERS.ANALYST;
    await db.analyst.upsert({
        where: { id: analystData.id },
        update: {
            name: analystData.name,
            email: analystData.email,
            status: client_1.AnalystStatus.ACTIVE,
        },
        create: {
            id: analystData.id,
            name: analystData.name,
            email: analystData.email,
            status: client_1.AnalystStatus.ACTIVE,
        },
    });
    const clientData = seed_constants_1.SEED_USERS.CLIENT;
    const mpinHash = await bcrypt.hash(clientData.mpin, 10);
    await db.user.upsert({
        where: { id: clientData.id },
        update: {
            mobile: clientData.mobile,
            mpinHash,
            firstName: 'Test',
            lastName: 'Client',
            email: clientData.email,
            status: client_1.UserStatus.ACTIVE,
        },
        create: {
            id: clientData.id,
            mobile: clientData.mobile,
            mpinHash,
            firstName: 'Test',
            lastName: 'Client',
            email: clientData.email,
            status: client_1.UserStatus.ACTIVE,
        },
    });
}
if (require.main === module) {
    seed()
        .then(() => {
        console.log('Database seeded successfully.');
        process.exit(0);
    })
        .catch((error) => {
        console.error('Error during database seeding:', error);
        process.exit(1);
    });
}
//# sourceMappingURL=seed.js.map