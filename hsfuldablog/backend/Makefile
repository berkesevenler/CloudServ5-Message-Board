CC = gcc
CFLAGS = -O2 -Wall
LIBS = -lmongoc-1.0 -lbson-1.0 -lpthread

SRC = app.c mongoose.c

server: $(SRC)
	$(CC) -o server $(SRC) $(CFLAGS) $(LIBS)

clean:
	rm -f server
