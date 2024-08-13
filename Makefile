CC := g++
CFLAGS := -g -Wall -pthread

SRC_DIR := . 

SRCS := $(shell find $(SRC_DIR) -name '*.cpp')

OBJS := $(SRCS:%=%.o)

main: $(OBJS)
	$(CC) $^ -o $@
	rm *.o

$(OBJS): %.cpp.o: %.cpp
	$(CC) $(CFLAGS) -c $< -o $@ 

s1:
	./main psw1 ex3.dat null psw2 100-110

s2:
	./main psw2 ex3.dat psw1 null 200-210
	
master:
	./main master 2

clean-fifo:
	find ./ -name "fifo*" -delete
