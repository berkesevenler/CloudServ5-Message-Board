# Use Alpine Linux as a lightweight base image
FROM alpine:latest

WORKDIR /app

RUN sed -i 's|dl-cdn.alpinelinux.org|mirror.sfo12.us.leaseweb.net|g' /etc/apk/repositories && \
    apk add --no-cache \
    gcc \
    musl-dev \
    libressl-dev \
    curl \
    mongo-c-driver-dev \
    make

# Download Mongoose (Lightweight HTTP Server Library)
RUN curl -fsSL https://mongoose.ws/download/mongoose.c -o mongoose.c

# Copy source files into the container
COPY . .

# Compile the C program
RUN gcc -o server app.c mongoose.c -lmongoc-1.0 -lbson-1.0 -lpthread -O2

# Expose port 5001 for the backend service
EXPOSE 5001

# Run the C server
CMD ["./server"]
