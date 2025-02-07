FROM debian:bookworm


WORKDIR /usr/src/app


# Install necessary dependencies

RUN apt-get update && \
    apt-get install -y wget gnupg cmake git build-essential pkg-config && \
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add - && \
    echo "deb [arch=arm64,amd64] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/6.0 main" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
    apt-get update && \
    apt-get install -y libmongoc-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy source code
COPY . .

# Compile the application
# RUN sudo gcc -o app app.c $(pkg-config --cflags --libs libmongoc-1.0) && sudo chmod +x app

# Expose port
EXPOSE 5001

# Run the compiled application
CMD ["bash"]