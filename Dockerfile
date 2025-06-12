FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Debug: Show package.json content
RUN echo "📋 Package.json found:" && \
    cat package.json | head -20

# Install production dependencies
RUN npm ci --only=production --silent

# Build stage
FROM base AS builder
WORKDIR /app

# Build arguments
ARG VITE_SUPABASE_URL
ARG VITE_SUPABASE_ANON_KEY
ARG OPENAI_API_KEY
ARG VITE_PROXY_SERVER
ARG VITE_PROXY_SERVER_PORT
ARG ALLOWED_ORIGINS
ARG RATE_LIMIT_REQUESTS_PER_MINUTE

# Copy source files
COPY package.json package-lock.json* ./
COPY . .

# Debug: Check what we have
RUN echo "🔍 Files in app directory:" && \
    ls -la && \
    echo "🔍 Checking if vite.config.js exists:" && \
    ls -la vite.config.* || echo "No vite config found" && \
    echo "🔍 Checking package scripts:" && \
    npm run || echo "No scripts found"

# Install ALL dependencies (dev + prod for build)
RUN npm install --silent

# Debug: Verify installations
RUN echo "📦 Installed packages:" && \
    npm list --depth=0 || echo "Package list failed" && \
    echo "🔍 Node modules:" && \
    ls -la node_modules/ | head -10

# Create .env file
RUN echo "VITE_SUPABASE_URL=${VITE_SUPABASE_URL}" > .env && \
    echo "VITE_SUPABASE_ANON_KEY=${VITE_SUPABASE_ANON_KEY}" >> .env && \
    echo "OPENAI_API_KEY=${OPENAI_API_KEY}" >> .env && \
    echo "VITE_PROXY_SERVER=${VITE_PROXY_SERVER}" >> .env && \
    echo "VITE_PROXY_SERVER_PORT=${VITE_PROXY_SERVER_PORT}" >> .env && \
    echo "ALLOWED_ORIGINS=${ALLOWED_ORIGINS}" >> .env && \
    echo "RATE_LIMIT_REQUESTS_PER_MINUTE=${RATE_LIMIT_REQUESTS_PER_MINUTE}" >> .env

# Debug: Show environment
RUN echo "📋 Environment file:" && \
    cat .env | sed 's/=.*/=***/'

# Try to build with verbose output
RUN echo "🚀 Starting build process..." && \
    npm run build --verbose || (echo "❌ Build failed. Showing error details:" && cat package.json && exit 1)

# Check build output
RUN echo "📦 Build completed. Contents:" && \
    ls -la && \
    if [ -d "dist" ]; then \
        echo "✅ dist folder found:" && \
        ls -la dist/; \
    else \
        echo "❌ No dist folder. Checking for other build outputs:" && \
        ls -la build/ || ls -la public/ || echo "No build output found"; \
    fi

# Production stage
FROM nginx:alpine AS runner

# Copy nginx config first
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built files
COPY --from=builder /app/dist /usr/share/nginx/html

# Set permissions
RUN chmod -R 755 /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]