# syntax=docker/dockerfile:1.7

FROM node:22-alpine AS base
ENV NEXT_TELEMETRY_DISABLED=1
WORKDIR /workspace/apps/web

FROM base AS deps
COPY apps/web/package.json apps/web/package-lock.json ./
RUN npm ci

FROM base AS builder
ENV NODE_ENV=production
COPY --from=deps /workspace/apps/web/package.json ./package.json
COPY --from=deps /workspace/apps/web/package-lock.json ./package-lock.json
COPY --from=deps /workspace/apps/web/node_modules ./node_modules
COPY apps/web/app ./app
COPY apps/web/lib ./lib
COPY apps/web/next-env.d.ts ./next-env.d.ts
COPY apps/web/next.config.ts ./next.config.ts
COPY apps/web/tsconfig.json ./tsconfig.json
RUN npm run build

FROM node:22-alpine AS runner
ENV HOSTNAME=0.0.0.0
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
ENV PORT=3000
WORKDIR /app
RUN addgroup -S nodejs -g 1001 && adduser -S nextjs -u 1001 -G nodejs
COPY --from=builder --chown=nextjs:nodejs /workspace/apps/web/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /workspace/apps/web/.next/static ./.next/static
USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]
