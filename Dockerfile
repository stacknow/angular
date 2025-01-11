# Stage 1: Build the Angular app
FROM node:18-alpine AS build

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application source code
COPY . .

# Build the Angular app
RUN npm run build --prod

# Stage 2: Serve the app with Nginx
FROM nginx:stable-alpine

# Create a custom Nginx configuration
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

# Copy the build output from Stage 1 to the Nginx html directory
COPY --from=build /app/dist/* /usr/share/nginx/html

# Expose port 80 to the outside world
EXPOSE 80

# Start the Nginx server
CMD ["nginx", "-g", "daemon off;"]
