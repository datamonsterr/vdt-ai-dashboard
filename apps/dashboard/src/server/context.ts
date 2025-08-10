import { PrismaClient } from '@prisma/client';
import { NextRequest } from 'next/server';
import { inferAsyncReturnType } from '@trpc/server';

const prisma = new PrismaClient();

export async function createTRPCContext({ req }: { req: NextRequest }) {
  void req;
  return {
    db: prisma,
  };
}

export type Context = inferAsyncReturnType<typeof createTRPCContext>;
