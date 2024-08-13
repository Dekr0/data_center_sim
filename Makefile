CC := g++
CFLAGS := -g -Wall -pthread

SRC_DIR := . 

SRCS := $(shell find $(SRC_DIR) -name '*.cpp')

OBJS := $(SRCS:%=%.o)

addr = 127.0.0.1
port = 9060

main: $(OBJS)
	$(CC) $^ -o $@
	rm *.o

$(OBJS): %.cpp.o: %.cpp
	$(CC) $(CFLAGS) -c $< -o $@ 

s1:
	./main psw1 ex3.dat null psw2 100-110 $(addr) $(port)

s2:
	./main psw2 ex3.dat psw1 null 200-210 $(addr) $(port)
	
master:
	./main master 1 $(port)

clean-fifo:
	find ./ -name "fifo*" -delete
