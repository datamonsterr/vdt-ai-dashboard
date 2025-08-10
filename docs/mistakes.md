Each mistakes is append at the bottom follow same structures.
---
# Go-server
1. Context: Setup project for user
2. Mistake: Create go-server folder and Dockerfile for go-server
3. Explain: There is no go-server for api routing, we use Nextjs dashboard handle the backend api route as well, Go is just for kafka consumer.
4. Scope: Deployment, Architecture
----

# Clerk middleware import
1. Context: Added Clerk authentication middleware to Next.js dashboard
2. Mistake: Imported removed `authMiddleware` from `@clerk/nextjs`
3. Explain: `@clerk/nextjs@5` uses `clerkMiddleware` from `@clerk/nextjs/server`, causing build failures
4. Scope: Authentication, Build
----