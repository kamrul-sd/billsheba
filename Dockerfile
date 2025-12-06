# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@9.0.6

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build the application
RUN pnpm build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Install pnpm in production image
RUN npm install -g pnpm@9.0.6

# Copy package files from builder
COPY package.json pnpm-lock.yaml ./

# Install production dependencies only
RUN pnpm install --frozen-lockfile --prod

# Copy built application from builder
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public

# Expose port 3000
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Start the application
CMD ["pnpm", "start"]
