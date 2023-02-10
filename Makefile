# Version from file
VERSION := $(shell cat version.txt)

# Folder and file names
ODIR = ./obj
SOURCES_DIR = ./src
BUILD_DIR = ./build
DIST_DIR = ./dist
EXE = SILYDEMO.TOS

# VASM PARAMETERS
# _DEBUG: 1 to enable debug, 0 to disable them
# To disable debug, make target DEBUG_MODE=0
DEBUG_MODE = 1
VASMFLAGS=-Faout -quiet -x -m68000 -spaces -showopt -devpac -D_DEBUG=$(DEBUG_MODE)
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
# Add the -s option to strip the binary
LINKFLAGS=-nostdlib -L$(LIBCMINI)/lib -lcmini -lgcc -Wl,--traditional-format

_OBJS = 

OBJS = $(patsubst %,$(ODIR)/%,$(_OBJS))

.PHONY: all
all: prepare sinwaves dist

.PHONY: release
release: prepare sinwaves dist

.PHONY: prepare
prepare: clean
	mkdir -p $(BUILD_DIR)

.PHONY: sinwaves
sinwaves:
	python src/scroller.py 
	python src/small_sprites.py
	python src/sprite_large.py

clean-compile : clean init.o loader.o loop.o print.o print_s.o rasters.o scroller.o sprite_s.o sprite_l.o tiles.o ym6.o main.o

init.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/init.s -o $(BUILD_DIR)/init.o

loader.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/loader.s -o $(BUILD_DIR)/loader.o

loop.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/loop.s -o $(BUILD_DIR)/loop.o

print.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/print.s -o $(BUILD_DIR)/print.o

print_s.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/print_s.s -o $(BUILD_DIR)/print_s.o

rasters.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/rasters.s -o $(BUILD_DIR)/rasters.o

scroller.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/scroller.s -o $(BUILD_DIR)/scroller.o

sprite_s.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/sprite_s.s -o $(BUILD_DIR)/sprite_s.o

sprite_l.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/sprite_l.s -o $(BUILD_DIR)/sprite_l.o

tiles.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/tiles.s -o $(BUILD_DIR)/tiles.o

ym6.o: prepare
	$(VASM) $(VASMFLAGS) $(SOURCES_DIR)/ym6.s -o $(BUILD_DIR)/ym6.o

# All C files
main.o: prepare
	$(CC) $(CFLAGS) $(SOURCES_DIR)/main.c -o $(BUILD_DIR)/main.o

main: main.o init.o loader.o loop.o print.o print_s.o rasters.o  scroller.o sprite_s.o sprite_l.o tiles.o ym6.o
	$(CC) $(LIBCMINI)/lib/crt0.o \
	      $(BUILD_DIR)/init.o \
	      $(BUILD_DIR)/loader.o \
	      $(BUILD_DIR)/loop.o \
	      $(BUILD_DIR)/print.o \
	      $(BUILD_DIR)/print_s.o \
	      $(BUILD_DIR)/rasters.o \
	      $(BUILD_DIR)/scroller.o \
		  $(BUILD_DIR)/sprite_s.o \
		  $(BUILD_DIR)/sprite_l.o \
		  $(BUILD_DIR)/tiles.o \
		  $(BUILD_DIR)/ym6.o \
		  $(BUILD_DIR)/main.o \
		  -o $(BUILD_DIR)/$(EXE) $(LINKFLAGS);

.PHONY: dist
dist: main
	mkdir -p $(DIST_DIR)
	cp $(BUILD_DIR)/$(EXE) $(DIST_DIR) 	

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(DIST_DIR)

## Tag this version
.PHONY: tag
tag:
	git tag v$(VERSION) && git push origin v$(VERSION) && \
	echo "Tagged: $(VERSION)"
