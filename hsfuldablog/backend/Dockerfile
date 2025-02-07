FROM gcc:latest

ENV http_proxy 127.0.0.1
ENV https_proxy 127.0.0.1

WORKDIR /usr/src/app


# Install necessary dependencies
RUN apt-get update && apt-get install -y libmongoc-1.0-0 libmongoc-1.0-dev pkg-config

# Copy source code
COPY . .

# Compile the application
RUN gcc -o app app.c $(pkg-config --cflags --libs libmongoc-1.0) && chmod +x app

# Expose port
EXPOSE 5001

# Run the compiled application
CMD ["./app"]