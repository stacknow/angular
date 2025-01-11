# Stage 1: Build the Angular SSR app
FROM node:18-alpine AS build

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the Angular application source code
COPY . .

# Build the Angular SSR application
RUN npm run build && npm run build:ssr

# Stage 2: Set up Nginx and Node.js runtime environment
FROM nginx:stable-alpine AS runtime

# Set the working directory for the Node.js server
WORKDIR /app

# Copy the built Angular SSR app from the previous stage
COPY --from=build /app/dist/angular-app /app/dist/angular-app

# Copy Nginx configuration
RUN echo 'worker_processes 1; \
events { worker_connections 1024; } \
http { \
    include       mime.types; \
    default_type  application/octet-stream; \
    access_log /dev/stdout; \
    error_log /dev/stderr warn; \
    sendfile        on; \
    upstream angular_app { \
        server 127.0.0.1:4000; \
    } \
    server { \
        listen       80; \
        server_name  localhost; \
        location / { \
            proxy_pass http://angular_app; \
            proxy_http_version 1.1; \
            proxy_set_header Upgrade $http_upgrade; \
            proxy_set_header Connection keep-alive; \
            proxy_set_header Host $host; \
            proxy_cache_bypass $http_upgrade; \
        } \
    } \
}' > /etc/nginx/nginx.conf

# Install Node.js for running the Angular SSR server
FROM node:18-alpine AS app

# Set the working directory inside the container
WORKDIR /app

# Copy the built SSR app from the build stage
COPY --from=build /app/dist/angular-app /app/dist/angular-app

# Copy package.json and install production dependencies
COPY package*.json ./
RUN npm install --only=production

# Expose the SSR server's port
EXPOSE 4000

# Start the Angular SSR server in the background
CMD ["node", "dist/angular-app/server/server.mjs"]

# Expose Nginx on port 80
EXPOSE 80

# Start Nginx as the primary entrypoint
CMD ["nginx", "-g", "daemon off;"]
