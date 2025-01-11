# Stage 1: Build the Angular app
FROM node:18-alpine AS build

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application source code
COPY . .

# Build the Angular application
RUN npm run build

# Stage 2: Serve the Angular app with Nginx
FROM nginx:stable-alpine

# Copy custom Nginx configuration
RUN echo 'worker_processes 1; \
events { worker_connections 1024; } \
http { \
    include       mime.types; \
    default_type  application/octet-stream; \
    access_log /dev/stdout; \
    error_log /dev/stderr warn; \
    sendfile        on; \
    server { \
        listen       80; \
        server_name  localhost; \
        location / { \
            root   /usr/share/nginx/html; \
            index  index.html; \
            try_files $uri /index.html; \
        } \
    } \
}' > /etc/nginx/nginx.conf

# Copy the Angular build output to the Nginx html directory
COPY --from=build /app/dist/angular-app /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
