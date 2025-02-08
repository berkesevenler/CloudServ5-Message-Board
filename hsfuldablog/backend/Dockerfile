FROM debian:bookworm


WORKDIR /usr/src/app


# Install necessary dependencies

RUN apt-get update && \
    apt-get install -y cmake build-essential pkg-config libmongoc-dev gcc curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and install Mongoose (if not included in your source)
RUN curl -O https://raw.githubusercontent.com/cesanta/mongoose/master/mongoose.h


# Copy source code
COPY server .

# Compile the application
RUN gcc -o app app.c $(pkg-config --cflags --libs libmongoc-1.0) -pthread -ldl && chmod +x app

# Expose port
EXPOSE 5001

# Run the compiled application
CMD ["./server"]