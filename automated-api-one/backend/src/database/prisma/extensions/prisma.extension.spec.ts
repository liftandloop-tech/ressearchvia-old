import { prismaExtension } from './prisma.extension';

describe('prismaExtension', () => {
  let mockPrisma: any;
  let extendedQuery: any;
  let extendedModel: any;

  beforeEach(() => {
    mockPrisma = {
      $extends: jest.fn().mockImplementation((config) => {
        extendedQuery = config.query?.$allModels;
        extendedModel = config.model;
        return {
          user: {
            findActive: config.model?.user?.findActive,
          },
        };
      }),
      user: {
        update: jest
          .fn()
          .mockResolvedValue({ id: 'user-1', deletedAt: new Date() }),
        updateMany: jest.fn().mockResolvedValue({ count: 5 }),
      },
      strategy: {
        update: jest.fn(),
      },
    };

    prismaExtension(mockPrisma);
  });

  describe('query extensions (soft delete)', () => {
    it('should convert delete to update for soft-delete models', async () => {
      const mockQuery = jest.fn();
      const args = { where: { id: 'user-1' } };

      await extendedQuery.delete({
        model: 'User',
        args,
        query: mockQuery,
      });

      expect(mockPrisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { deletedAt: expect.any(Date) },
      });
      expect(mockQuery).not.toHaveBeenCalled();
    });

    it('should bypass soft-delete update for non-soft-delete models', async () => {
      const mockQuery = jest.fn().mockResolvedValue({ success: true });
      const args = { where: { id: 'some-id' } };

      const result = await extendedQuery.delete({
        model: 'Trade',
        args,
        query: mockQuery,
      });

      expect(result).toEqual({ success: true });
      expect(mockQuery).toHaveBeenCalledWith(args);
    });

    it('should convert deleteMany to updateMany for soft-delete models', async () => {
      const mockQuery = jest.fn();
      const args = { where: { status: 'ACTIVE' } };

      await extendedQuery.deleteMany({
        model: 'User',
        args,
        query: mockQuery,
      });

      expect(mockPrisma.user.updateMany).toHaveBeenCalledWith({
        where: { status: 'ACTIVE' },
        data: { deletedAt: expect.any(Date) },
      });
      expect(mockQuery).not.toHaveBeenCalled();
    });

    it('should bypass soft-delete updateMany for non-soft-delete models', async () => {
      const mockQuery = jest.fn().mockResolvedValue({ count: 0 });
      const args = { where: { status: 'OPEN' } };

      const result = await extendedQuery.deleteMany({
        model: 'Trade',
        args,
        query: mockQuery,
      });

      expect(result).toEqual({ count: 0 });
      expect(mockQuery).toHaveBeenCalledWith(args);
    });

    it('should append deletedAt: null to findFirst for soft-delete models', async () => {
      const mockQuery = jest.fn().mockResolvedValue({ id: 'user-1' });
      const args: any = { where: { id: 'user-1' } };

      await extendedQuery.findFirst({
        model: 'User',
        args,
        query: mockQuery,
      });

      expect(args.where.deletedAt).toBeNull();
      expect(mockQuery).toHaveBeenCalledWith(args);
    });

    it('should keep custom deletedAt filter in findFirst', async () => {
      const mockQuery = jest.fn();
      const customDate = new Date();
      const args: any = { where: { id: 'user-1', deletedAt: customDate } };

      await extendedQuery.findFirst({
        model: 'User',
        args,
        query: mockQuery,
      });

      expect(args.where.deletedAt).toBe(customDate);
    });

    it('should append deletedAt: null to findMany/findUnique/count for soft-delete models', async () => {
      const mockQuery = jest.fn();

      const argsMany: any = {};
      await extendedQuery.findMany({
        model: 'User',
        args: argsMany,
        query: mockQuery,
      });
      expect(argsMany.where.deletedAt).toBeNull();

      const argsUnique: any = { where: { id: '1' } };
      await extendedQuery.findUnique({
        model: 'User',
        args: argsUnique,
        query: mockQuery,
      });
      expect(argsUnique.where.deletedAt).toBeNull();

      const argsCount: any = {};
      await extendedQuery.count({
        model: 'User',
        args: argsCount,
        query: mockQuery,
      });
      expect(argsCount.where.deletedAt).toBeNull();
    });
  });

  describe('model extensions', () => {
    it('should paginate results', async () => {
      const mockFindMany = jest
        .fn()
        .mockResolvedValue([{ id: '1' }, { id: '2' }]);
      const mockCount = jest.fn().mockResolvedValue(20);

      const context = {
        findMany: mockFindMany,
        count: mockCount,
      };

      const result = await extendedModel.$allModels.paginate.call(context, {
        page: 2,
        limit: 5,
        where: { role: 'CLIENT' },
      });

      expect(mockFindMany).toHaveBeenCalledWith({
        where: { role: 'CLIENT' },
        take: 5,
        skip: 5,
      });
      expect(mockCount).toHaveBeenCalledWith({ where: { role: 'CLIENT' } });
      expect(result).toEqual({
        data: [{ id: '1' }, { id: '2' }],
        total: 20,
        page: 2,
        limit: 5,
        totalPages: 4,
      });
    });

    it('should use default values in paginate', async () => {
      const mockFindMany = jest.fn().mockResolvedValue([]);
      const mockCount = jest.fn().mockResolvedValue(0);

      const context = {
        findMany: mockFindMany,
        count: mockCount,
      };

      const result = await extendedModel.$allModels.paginate.call(context);

      expect(mockFindMany).toHaveBeenCalledWith({
        take: 10,
        skip: 0,
      });
      expect(result.page).toBe(1);
      expect(result.limit).toBe(10);
    });

    it('should query active users in findActive', async () => {
      const mockFindMany = jest.fn().mockResolvedValue([]);
      mockPrisma.user.findMany = mockFindMany;

      const extendedClient = mockPrisma.$extends.mock.results[0].value;
      await extendedClient.user.findActive();

      expect(mockFindMany).toHaveBeenCalledWith({
        where: {
          status: 'ACTIVE',
          deletedAt: null,
        },
      });
    });
  });
});
