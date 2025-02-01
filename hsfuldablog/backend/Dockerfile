# Use a minimal base image for running the precompiled binary
FROM alpine:latest

WORKDIR /app

# Copy the precompiled binary into the container
COPY server .

# Expose the necessary port
EXPOSE 5001

# Run the server binary
CMD ["./server"]
