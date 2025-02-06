FROM gcc:latest

WORKDIR /app

# Install MongoDB C driver dependencies
RUN apt-get update && apt-get install -y \
    libmongoc-1.0-0 \
    libmongoc-dev \
    pkg-config

# Copy all source files
COPY . .

# Compile the application
RUN gcc -o app app.c $(pkg-config --libs --cflags libmongoc-1.0) -lmongoose

# Expose port
EXPOSE 5001

# Run the application
CMD ["./app"]