import { router } from '../trpc';
import { healthRouter } from './health';
import { projectsRouter } from './projects';
import { authRouter } from './auth';

export const appRouter = router({
  health: healthRouter,
  auth: authRouter,
  projects: projectsRouter,
});

export type AppRouter = typeof appRouter;
