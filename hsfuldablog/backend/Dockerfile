# --- Build Stage ---
    FROM alpine:latest AS build

    # Install build tools and the MongoDB C driver development package (provides bson headers)
    RUN apk add --no-cache gcc musl-dev curl git mongo-c-driver-dev
    
    WORKDIR /build
    
    # Copy source files and the include directory into the build stage.
    COPY src/ /build/
    COPY include/ /build/include/
    
    # If mongoose.c does not exist in the repository, download it.
    RUN test -f mongoose.c || curl -fsSL https://raw.githubusercontent.com/cesanta/mongoose/master/mongoose.c -o mongoose.c
    
    # Compile the server binary using the include directory.
    RUN gcc -O2 -Wall -I./include -lmongoc-1.0 -lbson-1.0 -lpthread -o server app.c mongoose.c
    
    # --- Runtime Stage ---
    FROM alpine:latest
    
    # Install only the runtime MongoDB C driver.
    RUN apk add --no-cache mongo-c-driver
    
    WORKDIR /app
    
    # Copy the compiled server binary from the build stage.
    COPY --from=build /build/server .
    
    EXPOSE 5001
    
    CMD ["./server"]
    