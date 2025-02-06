FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY . .

# Install dependencies
RUN npm install

# Expose port
EXPOSE 5001

# Start the server directly with npm
CMD ["node", "index.js"]