# Use a lightweight nginx image
FROM nginx:alpine

# Copy your static files to nginx's web directory
COPY ./ /usr/share/nginx/html

# Expose port 80 to make it accessible
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
