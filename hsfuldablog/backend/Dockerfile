# Dockerfile
# Use Node.js official image
FROM node:18

WORKDIR /usr/src/app

# Copy package.json first for caching layers
COPY package.json ./

# Install cors (this is separate, as per your file)
RUN npm install cors

# Install dependencies (this will create a package-lock.json inside the container)
RUN npm install --omit=dev

# Copy the rest of the source code
COPY . .

# Expose the server port
EXPOSE 5001

# Run the Express server
CMD ["node", "server.js"]
