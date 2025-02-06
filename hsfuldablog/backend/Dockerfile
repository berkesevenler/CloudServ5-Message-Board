FROM gcc:latest

WORKDIR /usr/src/app

# Copy package files
COPY . .

RUN gcc -o app app.c $(pkg-config --cflags --libs libmongoc-1.0)

# Expose port
EXPOSE 5001


CMD ["./app"]