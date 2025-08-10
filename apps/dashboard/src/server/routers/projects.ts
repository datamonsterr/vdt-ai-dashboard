import { z } from 'zod';
import { router, publicProcedure } from '../trpc';

export const projectsRouter = router({
  list: publicProcedure.query(async ({ ctx }) => {
    return ctx.db.project.findMany();
  }),
  create: publicProcedure
    .input(
      z.object({
        organizationId: z.string(),
        name: z.string(),
        slug: z.string(),
        description: z.string().optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      return ctx.db.project.create({ data: input });
    }),
});
