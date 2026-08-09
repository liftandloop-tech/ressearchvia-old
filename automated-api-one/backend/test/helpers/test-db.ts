export class TestDbHelper {
  constructor(private readonly prismaMock: any) {}

  clearDb() {
    jest.clearAllMocks();
  }

  seedMockUser(user: any) {
    this.prismaMock.user.findUnique.mockResolvedValue(user);
    this.prismaMock.user.findFirst.mockResolvedValue(user);
  }

  seedMockSegment(segment: any) {
    this.prismaMock.segment.findMany.mockResolvedValue([segment]);
  }
}
