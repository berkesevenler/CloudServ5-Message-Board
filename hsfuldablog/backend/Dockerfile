FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY . .

RUN gcc -o app app.c $(pkg-config --libs --cflags libmongoc-1.0) -lmongoose

# Expose port
EXPOSE 5001

# Start the server directly with npm
CMD ["./app"]