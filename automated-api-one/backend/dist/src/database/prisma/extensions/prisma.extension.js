"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.prismaExtension = void 0;
const modelsWithSoftDelete = [
    'User',
    'SegmentMaster',
    'UserSegment',
    'UserBroker',
    'Subscription',
    'Consent',
    'UserDevice',
];
const prismaExtension = (prisma) => {
    return prisma.$extends({
        query: {
            $allModels: {
                async delete({ model, args, query }) {
                    if (modelsWithSoftDelete.includes(model)) {
                        const modelKey = model.charAt(0).toLowerCase() + model.slice(1);
                        return prisma[modelKey].update({
                            where: args.where,
                            data: { deletedAt: new Date() },
                        });
                    }
                    return query(args);
                },
                async deleteMany({ model, args, query }) {
                    if (modelsWithSoftDelete.includes(model)) {
                        const modelKey = model.charAt(0).toLowerCase() + model.slice(1);
                        return prisma[modelKey].updateMany({
                            where: args.where,
                            data: { deletedAt: new Date() },
                        });
                    }
                    return query(args);
                },
                async findFirst({ model, args, query }) {
                    if (modelsWithSoftDelete.includes(model)) {
                        args.where = args.where || {};
                        if (args.where.deletedAt === undefined) {
                            args.where.deletedAt = null;
                        }
                    }
                    return query(args);
                },
                async findMany({ model, args, query }) {
                    if (modelsWithSoftDelete.includes(model)) {
                        args.where = args.where || {};
                        if (args.where.deletedAt === undefined) {
                            args.where.deletedAt = null;
                        }
                    }
                    return query(args);
                },
                async findUnique({ model, args, query }) {
                    if (modelsWithSoftDelete.includes(model)) {
                        args.where = args.where || {};
                        if (args.where.deletedAt === undefined) {
                            args.where.deletedAt = null;
                        }
                    }
                    return query(args);
                },
                async count({ model, args, query }) {
                    if (modelsWithSoftDelete.includes(model)) {
                        args.where = args.where || {};
                        if (args.where.deletedAt === undefined) {
                            args.where.deletedAt = null;
                        }
                    }
                    return query(args);
                },
            },
        },
        model: {
            $allModels: {
                async paginate(args = {}) {
                    const page = args.page || 1;
                    const limit = args.limit || 10;
                    const skip = (page - 1) * limit;
                    const { page: _p, limit: _l, ...findManyArgs } = args;
                    const [data, total] = await Promise.all([
                        this.findMany({ ...findManyArgs, take: limit, skip }),
                        this.count({ where: args.where }),
                    ]);
                    return {
                        data,
                        total,
                        page,
                        limit,
                        totalPages: Math.ceil(total / limit),
                    };
                },
            },
            user: {
                async findActive() {
                    return prisma.user.findMany({
                        where: {
                            status: 'ACTIVE',
                            deletedAt: null,
                        },
                    });
                },
            },
        },
    });
};
exports.prismaExtension = prismaExtension;
//# sourceMappingURL=prisma.extension.js.map