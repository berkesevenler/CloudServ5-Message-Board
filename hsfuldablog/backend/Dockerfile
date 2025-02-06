FROM node:latest

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install
RUN npm install cors  # Add cors package if not already in package.json

# Copy all source files
COPY . .

# Expose port
EXPOSE 5001

# Start the server directly with npm
CMD ["npm", "start"]