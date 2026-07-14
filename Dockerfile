# Use nginx alpine for a lightweight image
FROM nginx:alpine

# Copy static website files to nginx html directory
COPY index.html /usr/share/nginx/html/
COPY blog.html /usr/share/nginx/html/
COPY blog-details.html /usr/share/nginx/html/
COPY blog-details-bl653.html /usr/share/nginx/html/
COPY assets/ /usr/share/nginx/html/assets/

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

