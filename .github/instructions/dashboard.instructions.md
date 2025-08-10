---
applyTo: apps/dashboard/**/*
---

# Purpose
Next.js 15 TypeScript dashboard for monitoring AI/ML pipelines and data quality.

# Tech Stack
- **Framework**: Next.js 15 with App Router
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS v4
- **UI**: shadcn/ui (black/white theme)
- **Charts**: Recharts
- **Auth**: Clerk
- **API**: tRPC for type-safe APIs
- **Database**: Prisma ORM + PostgreSQL
- **Package Manager**: pnpm (required)

# Package Management
1. **Must use pnpm** - never npm or yarn
2. Add shadcn/ui components: `pnpm run ui {component-name}`
3. Commit `pnpm-lock.yaml`

# UI Guidelines
1. **Theme**: Black and white only, minimal colors
2. **Components**: Prefer shadcn/ui over custom UI
3. **Charts**: Use Recharts for all visualizations
4. **Icons**: Lucide React (included with shadcn/ui)
5. **Layout**: Mobile-first responsive design

# Coding Style
1. **Architecture**: 
   - Write small, reusable components first
   - Compose pages from smaller components
   - Avoid monolithic components (>200 lines)

2. **File Structure**:
   ```
   src/
   ├── app/           # Pages (App Router)
   │   └── api/trpc/  # tRPC API routes
   ├── components/    # Reusable components
   │   ├── ui/       # shadcn/ui components
   │   └── charts/   # Chart components
   ├── server/       # tRPC server configuration
   │   ├── routers/  # tRPC route handlers
   │   ├── procedures/ # Reusable procedures
   │   └── context.ts # Request context
   ├── lib/          # Utils
   ├── hooks/        # Custom hooks
   └── types/        # TypeScript types
   ```

3. **TypeScript**:
   - Strict mode enabled
   - Define interfaces for all data
   - Avoid `any`, use `unknown` if needed
   - Import types from `packages/proto-types`

4. **Naming**:
   - Components: `PascalCase.tsx`
   - Files: `kebab-case.ts`
   - Functions: `camelCase`
   - Constants: `UPPER_SNAKE_CASE`

# Data & State
1. **API**: Use tRPC for type-safe API calls with React Query
2. **State**: React hooks + Context API (Zustand for complex state)
3. **Multi-tenancy**: Ensure organization data isolation
4. **Types**: Use protobuf types when available

# tRPC API Guidelines

## tRPC Patterns
```typescript
// Router organization
export const metricsRouter = router({
  getMetrics: publicProcedure
    .input(z.object({ orgId: z.string() }))
    .query(async ({ input, ctx }) => {
      return await ctx.db.metrics.findMany({ 
        where: { organizationId: input.orgId } 
      });
    }),
  
  createMetric: protectedProcedure
    .input(createMetricSchema)
    .mutation(async ({ input, ctx }) => {
      return await ctx.db.metrics.create({ data: input });
    }),
});
```

## Authentication & Database
```typescript
// Context with auth and database
export const createTRPCContext = async ({ req }: { req: NextRequest }) => {
  const { userId, orgId } = auth();
  return {
    db: prisma,
    userId,
    orgId,
  };
};

// Protected procedure
export const protectedProcedure = publicProcedure.use(({ ctx, next }) => {
  if (!ctx.userId) throw new TRPCError({ code: 'UNAUTHORIZED' });
  return next({ ctx: { ...ctx, userId: ctx.userId } });
});
```

## API Guidelines
1. **Validation**: Use Zod schemas for input validation
2. **Multi-tenancy**: Organization-based data isolation in procedures
3. **Type Safety**: End-to-end type safety with tRPC
4. **Error Handling**: Use tRPC error codes and proper status codes

# Performance
1. Use `React.memo()` for expensive components
2. Proper `key` props for lists
3. `useMemo()`/`useCallback()` judiciously
4. Lazy load with `React.lazy()`
5. Debounce real-time updates

# Authentication
1. Use Clerk React hooks
2. Implement route protection
3. Handle organization switching
4. Pass organization context to API calls

# Code Quality
1. **Tools**: ESLint, Prettier, TypeScript
2. **Rules**: Components <200 lines, functions <50 lines
3. **Testing**: Jest + React Testing Library + Playwright
4. Run `pnpm run lint` before commits

# Development
1. Dev server: `pnpm run dev`
2. Build with Turbopack
3. Test components in isolation
4. Use proper environment variables 