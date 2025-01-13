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

# Copy the built Angular app to the Nginx HTML directory (only the 'browser' directory)
COPY --from=build /app/dist/angular-app/browser /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
