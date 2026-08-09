import { PrismaClient } from '@prisma/client';

const modelsWithSoftDelete = [
  'User',
  'SegmentMaster',
  'UserSegment',
  'UserBroker',
  'Subscription',
  'Consent',
  'UserDevice',
];

export const prismaExtension = (prisma: PrismaClient) => {
  return prisma.$extends({
    query: {
      $allModels: {
        async delete({ model, args, query }) {
          if (modelsWithSoftDelete.includes(model)) {
            const modelKey = model.charAt(0).toLowerCase() + model.slice(1);
            return (prisma as any)[modelKey].update({
              where: args.where,
              data: { deletedAt: new Date() },
            });
          }
          return query(args);
        },
        async deleteMany({ model, args, query }) {
          if (modelsWithSoftDelete.includes(model)) {
            const modelKey = model.charAt(0).toLowerCase() + model.slice(1);
            return (prisma as any)[modelKey].updateMany({
              where: args.where,
              data: { deletedAt: new Date() },
            });
          }
          return query(args);
        },
        async findFirst({ model, args, query }) {
          if (modelsWithSoftDelete.includes(model)) {
            args.where = args.where || {};
            if ((args.where as any).deletedAt === undefined) {
              (args.where as any).deletedAt = null;
            }
          }
          return query(args);
        },
        async findMany({ model, args, query }) {
          if (modelsWithSoftDelete.includes(model)) {
            args.where = args.where || {};
            if ((args.where as any).deletedAt === undefined) {
              (args.where as any).deletedAt = null;
            }
          }
          return query(args);
        },
        async findUnique({ model, args, query }) {
          if (modelsWithSoftDelete.includes(model)) {
            args.where = args.where || {};
            if ((args.where as any).deletedAt === undefined) {
              (args.where as any).deletedAt = null;
            }
          }
          return query(args);
        },
        async count({ model, args, query }) {
          if (modelsWithSoftDelete.includes(model)) {
            args.where = args.where || {};
            if ((args.where as any).deletedAt === undefined) {
              (args.where as any).deletedAt = null;
            }
          }
          return query(args);
        },
      },
    },
    model: {
      $allModels: {
        async paginate<T, A>(
          this: T,
          args: {
            page?: number;
            limit?: number;
            where?: any;
            orderBy?: any;
            include?: any;
          } = {},
        ) {
          const page = args.page || 1;
          const limit = args.limit || 10;
          const skip = (page - 1) * limit;

          const { page: _p, limit: _l, ...findManyArgs } = args as any;

          const [data, total] = await Promise.all([
            (this as any).findMany({ ...findManyArgs, take: limit, skip }),
            (this as any).count({ where: args.where }),
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
export type ExtendedPrismaClient = ReturnType<typeof prismaExtension>;
