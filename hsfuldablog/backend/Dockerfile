FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all source files
COPY . .

# Expose port
EXPOSE 5001

# Set environment variables
ENV NODE_ENV=production

# Start the server directly with node
CMD ["node", "index.js"]