FROM debian:bookworm


WORKDIR /usr/src/app


# Install necessary dependencies

RUN apt-get update && \
    apt-get install -y cmake build-essential pkg-config libmongoc-dev gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy source code
COPY . .

# Compile the application
RUN gcc -o app app.c $(pkg-config --cflags --libs libmongoc-1.0) && chmod +x app

# Expose port
EXPOSE 5001

# Run the compiled application
CMD ["./app"]