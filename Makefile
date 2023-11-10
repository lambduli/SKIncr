CC=clang-10
CPP=clang++-10
LLC=llc-10

OLEVEL=-O2
CC32FLAGS=-DSKIP32 --target=wasm32 -emit-llvm
CC64FLAGS=$(OLEVEL) -DSKIP64
CPPFLAGS=$(OLEVEL) -std=c++17
SKFLAGS=

SKIP_FILES=$(shell find . -name "*.sk")
CFILES=\
	runtime/copy.c \
	runtime/free.c \
	runtime/hash.c \
	runtime/hashtable.c \
	runtime/intern.c \
	runtime/memory.c \
	runtime/obstack.c \
	runtime/runtime.c \
	runtime/stdlib.c \
	runtime/stack.c \
	runtime/string.c \
	runtime/native_eq.c

NATIVE_FILES=\
	runtime/palloc.c\
	runtime/consts.c

CFILES32=$(CFILES) runtime/runtime32_specific.c
CFILES64=$(CFILES) runtime/runtime64_specific.cpp $(NATIVE_FILES)
BCFILES32=build/magic.bc $(addprefix build/,$(CFILES32:.c=.bc))
OFILES=$(addprefix build/,$(CFILES:.c=.o))
ONATIVE_FILES= build/magic.o $(addprefix build/,$(NATIVE_FILES:.c=.o))

default: build/skia

.PHONY: default

build/skc:
	mkdir -p build
	gunzip -c prebuild/preamble_and_skc_out64.ll.gz > build/preamble_and_skc_out64.ll
	make build/libskip_runtime64.a
	$(CPP) $(CPPFLAGS) build/preamble_and_skc_out64.ll build/libskip_runtime64.a -o build/skc -lrt -lpthread

build/magic.c:
	date | cksum | awk '{print "unsigned long version = " $$1 ";"}' > build/magic.c
	echo "int SKIP_get_version() { return (int)version; }" >> build/magic.c

build/magic.o: build/magic.c
	mkdir -p build/runtime
	$(CC) $(CC64FLAGS) -o $@ -c $<

build/libskip_runtime64.a: $(OFILES) build/runtime/runtime64_specific.o $(ONATIVE_FILES)
	ar rcs build/libskip_runtime64.a $(OFILES) build/runtime/runtime64_specific.o $(ONATIVE_FILES)

build/runtime/runtime64_specific.o: runtime/runtime64_specific.cpp
	$(CPP) $(CPPFLAGS) -c runtime/runtime64_specific.cpp -o build/runtime/runtime64_specific.o

build/%.o: %.c
	mkdir -p build/runtime
	$(CC) $(CC64FLAGS) -o $@ -c $<

build/skia: build/out64.ll ./build/libskip_runtime64.a
	$(CPP) $(CPPFLAGS) build/out64.ll ./build/libskip_runtime64.a -o build/skia -lrt -lpthread

build/out64.ll: $(SKIP_FILES) build/skc
	mkdir -p build/
	build/skc --preamble prebuild/preamble64.ll --embedded64 $(SKIP_FILES) --export-function-as main=skip_main $(SKFLAGS) --output build/out64.ll

#-------------------------------------------------------
# Run

test: build/skia
	./build/skia --test

valgrind: build/skia
	valgrind ./build/skia --run ./tests/stdlib.sm $(RUN)

analyze: build/skia
	./build/skia --print_simple --print_ir ./tests/stdlib.sm $(RUN)

run: build/skia
	./build/skia --run ./tests/stdlib.sm $(RUN)

.PHONY: test valgrind

#-------------------------------------------------------
# Docker

docker: docker_container
	docker run -it -v `pwd`:/jan/SKIncr buildme bash

docker_container:
	$(MAKE) -C ./Docker $(ARCH)

.PHONY: docker docker_container

#-------------------------------------------------------

clean:
	rm -Rf build

.PHONY: clean
