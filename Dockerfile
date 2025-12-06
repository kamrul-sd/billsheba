# ---------- Stage 1: Builder ----------
FROM node:20-alpine AS builder

WORKDIR /app

# Install pnpm globally
RUN npm install -g pnpm

# Copy package files first for better caching
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the project
COPY . .

# Build Next.js (no standalone mode)
RUN pnpm run build


# ---------- Stage 2: Runner ----------
FROM node:20-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

# Install pnpm (needed only if your build expects it)
RUN npm install -g pnpm

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy only what is needed for production
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Copy node_modules from the builder stage
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules

USER nextjs

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["pnpm", "start"]


# # ---------- Stage 1: Build ----------
# FROM node:20-alpine AS builder

# WORKDIR /app

# # Install pnpm globally
# RUN npm install -g pnpm

# # Copy package manifests first (for better caching)
# COPY package.json pnpm-lock.yaml ./

# # Install dependencies
# RUN pnpm install --frozen-lockfile

# # Copy the rest of the source code
# COPY . .

# # Build Next.js app for production (creates .next/standalone)
# RUN pnpm run build

# # ---------- Stage 2: Run ----------
# FROM node:20-alpine AS runner

# WORKDIR /app

# ENV NODE_ENV=production

# # Create a non-root user for security
# RUN addgroup --system --gid 1001 nodejs && \
#     adduser --system --uid 1001 nextjs

# # Copy standalone build files from builder stage
# # Next.js standalone output includes node_modules and server.js in .next/standalone
# COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
# COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
# COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# # Switch to non-root user
# USER nextjs

# # Expose the port that Next.js runs on
# EXPOSE 3000

# ENV PORT=3000
# ENV HOSTNAME="0.0.0.0"

# # Run the app
# CMD ["node", "server.js"]
