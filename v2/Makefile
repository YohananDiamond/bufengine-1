BUILD := build
PROGRAM := $(BUILD)/bufengine_editor
CC := gcc
CFLAGS := -Wall -O3 -std=c89 -lncurses
SRC := $(wildcard src/*.c)

$(PROGRAM): $(SRC)
	mkdir -p $(BUILD)
	$(CC) $(CFLAGS) $(SRC) -o $(PROGRAM)

run: $(PROGRAM)
	exec $(PROGRAM)

.PHONY: run
