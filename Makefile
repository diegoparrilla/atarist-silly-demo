ODIR = ./obj
SOURCES_DIR = ./src
BUILD_DIR = ./build
DIST_DIR = ./dist
EXE = test.tos

# VASM PARAMETERS
VASMFLAGS=-Faout -quiet -x -m68000 -spaces -showopt -devpac
VASM = stcmd vasm 
VLINK = stcmd vlink

# LIBCMINI PARAMETERS
# IMPORTANT! There is functional verson of the LIBCMINI library in the docker image
# To reference the library, it must set the absolute path inside the container image
# The library is stored in /freemint/libcmini 
# More info about the library: https://github.com/freemint/libcmini
LIBCMINI = /freemint/libcmini

# GCC PARAMETERS
CC = stcmd gcc
CFLAGS=-c -std=gnu99 -I$(LIBCMINI)/include -g

# LINKER PARAMETERS
LINKFLAGS=-nostdlib -s -L$(LIBCMINI)/lib -lcmini -lgcc -Wl,--traditional-format

_OBJS = hello.o

OBJS = $(patsubst %,$(ODIR)/%,$(_OBJS))

.PHONY: all
all: prepare dist

.PHONY: prepare
prepare: clean
	mkdir -p $(BUILD_DIR)

clean-compile : clean loader.o loop.o print.o rasters.o screen.o scroller.o tiles.o main.o

loader.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/loader.s -o $(BUILD_DIR)/loader.o

loop.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/loop.s -o $(BUILD_DIR)/loop.o

print.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/print.s -o $(BUILD_DIR)/print.o

rasters.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/rasters.s -o $(BUILD_DIR)/rasters.o

scroller.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/scroller.s -o $(BUILD_DIR)/scroller.o

tiles.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/tiles.s -o $(BUILD_DIR)/tiles.o

# All C files
screen.o: prepare
	$(CC) $(CFLAGS) $(SOURCES_DIR)/screen.c -o $(BUILD_DIR)/screen.o

main.o: prepare
	$(CC) $(CFLAGS) $(SOURCES_DIR)/main.c -o $(BUILD_DIR)/main.o

main: main.o screen.o loader.o loop.o print.o rasters.o  scroller.o tiles.o
	$(CC) $(LIBCMINI)/lib/crt0.o \
	      $(BUILD_DIR)/loader.o \
	      $(BUILD_DIR)/loop.o \
	      $(BUILD_DIR)/print.o \
	      $(BUILD_DIR)/rasters.o \
	      $(BUILD_DIR)/scroller.o \
		  $(BUILD_DIR)/screen.o \
		  $(BUILD_DIR)/tiles.o \
		  $(BUILD_DIR)/main.o \
		  -o $(BUILD_DIR)/test.tos $(LINKFLAGS);

.PHONY: dist
dist: main
	mkdir -p $(DIST_DIR)
	cp $(BUILD_DIR)/$(EXE) $(DIST_DIR) 	

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(DIST_DIR)