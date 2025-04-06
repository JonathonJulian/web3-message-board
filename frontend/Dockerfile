FROM node:20-alpine AS base

WORKDIR /app

# Install dependencies
FROM base AS deps
RUN npm install -g pnpm

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
RUN pnpm add -D @sveltejs/adapter-node

# Build stage
FROM deps AS builder
COPY . .

# Update the Svelte config to use Node adapter
RUN sed -i 's/adapter-static/adapter-node/g' svelte.config.js

# Build the application
RUN pnpm build

# Production image
FROM node:20-alpine AS production

WORKDIR /app

# Copy built application
COPY --from=builder /app/package.json ./
COPY --from=builder /app/dist ./dist

# Use npm instead of pnpm for production
# Convert pnpm dependencies to npm format
RUN npm install --omit=dev

# Expose port
EXPOSE 3000

# Set environment variables
ENV PORT=3000 \
    HOST=0.0.0.0 \
    NODE_ENV=production

# Run the app
CMD ["node", "./dist/index.js"]
