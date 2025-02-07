FROM debian:latest


WORKDIR /usr/src/app


# Install necessary dependencies

RUN sudo apt-get update && sudo apt-get install -y libmongoc-1.0-0 libmongoc-1.0-dev pkg-config

# Copy source code
COPY . .

# Compile the application
RUN sudo gcc -o app app.c $(pkg-config --cflags --libs libmongoc-1.0) && sudo chmod +x app

# Expose port
EXPOSE 5001

# Run the compiled application
CMD ["./app"]