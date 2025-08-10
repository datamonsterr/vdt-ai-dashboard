import { PrismaClient } from '@prisma/client';
import { fakeOrganizationComplete, fakeProject } from '../prisma/fake-data';

const prisma = new PrismaClient();

/**
 * Initialize database with demo data using faker generators.
 * Can be reused in tests or local development.
 */
export async function initDemo() {
  // create an organization with a couple of projects
  const org = await prisma.organization.create({
    data: {
      ...fakeOrganizationComplete(),
      projects: {
        create: Array.from({ length: 2 }).map(() => fakeProject()),
      },
    },
    include: { projects: true },
  });
  return org;
}

if (require.main === module) {
  initDemo().finally(() => prisma.$disconnect());
}
