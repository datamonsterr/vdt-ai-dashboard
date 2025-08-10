import { router, publicProcedure } from '../trpc';
import type { User, UserRole } from '@vdt-ai/proto-types';

export const authRouter = router({
  whoAmI: publicProcedure.query(() => {
    const user: User = {
      id: 'demo-user',
      email: 'demo@example.com',
      name: 'Demo User',
      role: 1 as UserRole,
    };
    return { user };
  }),
});
