import { describe, expect, it } from 'vitest';
import { appRouter } from '../routers/_app';
import type { PrismaClient } from '@prisma/client';

interface Project {
  id: string;
  organizationId: string;
  name: string;
  slug: string;
  description?: string;
}

function createMockDb() {
  const data: Project[] = [];
  return {
    project: {
      findMany: async (): Promise<Project[]> => data,
      create: async ({ data: input }: { data: Omit<Project, 'id'> }): Promise<Project> => {
        const record: Project = { id: `p${data.length + 1}`, ...input };
        data.push(record);
        return record;
      },
    },
  };
}

describe('tRPC API', () => {
  const caller = appRouter.createCaller({ db: createMockDb() as unknown as PrismaClient });

  it('returns health status', async () => {
    const res = await caller.health.check();
    expect(res.status).toBe('ok');
  });

  it('returns demo user', async () => {
    const res = await caller.auth.whoAmI();
    expect(res.user.email).toBe('demo@example.com');
  });

  it('creates and lists projects', async () => {
    await caller.projects.create({ organizationId: 'org1', name: 'Demo', slug: 'demo' });
    const list = await caller.projects.list();
    expect(list.length).toBe(1);
    expect(list[0].name).toBe('Demo');
  });

  it('fails validation when required fields are missing', async () => {
    // @ts-expect-error - slug is required by schema
    await expect(caller.projects.create({ organizationId: 'org1', name: 'Demo' })).rejects.toThrow();
  });
});
