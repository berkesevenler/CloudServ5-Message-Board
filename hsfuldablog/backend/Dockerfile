# Use a lightweight Debian-based image with build tools
FROM debian:bullseye-slim

WORKDIR /app

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    make \
    libc-dev \
    libssl-dev \
    libmongoc-dev \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Mongoose (Lightweight HTTP Server Library)
RUN curl -fsSL https://mongoose.ws/download/mongoose.c -o mongoose.c

# Copy source files into the container
COPY . .

# Compile the C program
RUN gcc -o server server.c mongoose.c -lmongoc-1.0 -lbson-1.0 -lpthread -O2

# Expose port
EXPOSE 5001

# Run the C server
CMD ["./server"]
