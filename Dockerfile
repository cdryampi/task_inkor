FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Copy package files (incluir package-lock.json si existe)
COPY package.json package-lock.json* ./
RUN npm ci --only=production --silent

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app

# ✅ MOVER LOS ARG AQUÍ donde se usan
ARG VITE_SUPABASE_URL
ARG VITE_SUPABASE_ANON_KEY
ARG OPENAI_API_KEY
ARG VITE_PROXY_SERVER
ARG VITE_PROXY_SERVER_PORT
ARG ALLOWED_ORIGINS
ARG RATE_LIMIT_REQUESTS_PER_MINUTE

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Debug: Verificar que las variables están disponibles
RUN echo "🔍 Checking build variables:" && \
    echo "VITE_SUPABASE_URL: ${VITE_SUPABASE_URL:+SET}" && \
    echo "VITE_SUPABASE_ANON_KEY: ${VITE_SUPABASE_ANON_KEY:+SET}" && \
    echo "OPENAI_API_KEY: ${OPENAI_API_KEY:+SET}"

# Create .env file from environment variables at build time
RUN echo "VITE_SUPABASE_URL=${VITE_SUPABASE_URL}" > .env && \
    echo "VITE_SUPABASE_ANON_KEY=${VITE_SUPABASE_ANON_KEY}" >> .env && \
    echo "OPENAI_API_KEY=${OPENAI_API_KEY}" >> .env && \
    echo "VITE_PROXY_SERVER=${VITE_PROXY_SERVER}" >> .env && \
    echo "VITE_PROXY_SERVER_PORT=${VITE_PROXY_SERVER_PORT}" >> .env && \
    echo "ALLOWED_ORIGINS=${ALLOWED_ORIGINS}" >> .env && \
    echo "RATE_LIMIT_REQUESTS_PER_MINUTE=${RATE_LIMIT_REQUESTS_PER_MINUTE}" >> .env

# Install ALL dependencies (including devDependencies for build)
RUN npm install --silent

# Debug: Show .env content (masked)
RUN echo "📋 Environment file created:" && \
    cat .env | sed 's/=.*/=***MASKED***/'

# Build the project
RUN npm run build

# Debug: Verify build output
RUN echo "📦 Build completed. Checking dist folder:" && \
    ls -la dist/ || echo "❌ dist folder not found"

# Production image, copy all the files and run the app
FROM nginx:alpine AS runner
WORKDIR /usr/share/nginx/html

# Copy the built assets from the builder stage
COPY --from=builder /app/dist .

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx server
CMD ["nginx", "-g", "daemon off;"]