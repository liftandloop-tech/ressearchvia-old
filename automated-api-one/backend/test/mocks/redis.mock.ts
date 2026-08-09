export class MockRedis {
  private store = new Map<string, string>();

  async get(key: string): Promise<string | null> {
    return this.store.get(key) || null;
  }

  async set(
    key: string,
    value: string,
    mode?: string,
    duration?: number,
  ): Promise<string> {
    this.store.set(key, value);
    return 'OK';
  }

  async del(key: string): Promise<number> {
    const deleted = this.store.delete(key);
    return deleted ? 1 : 0;
  }

  async expire(key: string, seconds: number): Promise<number> {
    return this.store.has(key) ? 1 : 0;
  }

  async quit(): Promise<string> {
    return 'OK';
  }

  async ping(): Promise<string> {
    return 'PONG';
  }
}

export const mockQueue = () => ({
  add: jest.fn().mockImplementation((name, data) => {
    return Promise.resolve({ id: `mock_job_${Date.now()}`, name, data });
  }),
  process: jest.fn(),
});

export const mockWorker = () => ({
  on: jest.fn(),
  close: jest.fn(),
});
