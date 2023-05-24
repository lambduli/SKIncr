CC=clang-10
CPP=clang++-10
LLC=llc-10

OLEVEL=-O2
CC32FLAGS=-DSKIP32 --target=wasm32 -emit-llvm
CC64FLAGS=$(OLEVEL) -DSKIP64
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

build/skc:
	mkdir -p build
	gunzip -c prebuild/preamble_and_skc_out64.ll.gz > build/preamble_and_skc_out64.ll
	make build/libskip_runtime64.a
	clang++-10 $(OLEVEL) build/preamble_and_skc_out64.ll build/libskip_runtime64.a -o build/skc -lrt -lpthread

build/magic.c:
	date | cksum | awk '{print "unsigned long version = " $$1 ";"}' > build/magic.c
	echo "int SKIP_get_version() { return (int)version; }" >> build/magic.c

build/magic.o: build/magic.c
	mkdir -p build/runtime
	$(CC) $(CC64FLAGS) -o $@ -c $<

build/libskip_runtime64.a: $(OFILES) build/runtime/runtime64_specific.o $(ONATIVE_FILES)
	ar rcs build/libskip_runtime64.a $(OFILES) build/runtime/runtime64_specific.o $(ONATIVE_FILES)

build/runtime/runtime64_specific.o: runtime/runtime64_specific.cpp
	$(CPP) $(OLEVEL) -c runtime/runtime64_specific.cpp -o build/runtime/runtime64_specific.o

build/%.o: %.c
	mkdir -p build/runtime
	$(CC) $(CC64FLAGS) -o $@ -c $<

build/skia: build/out64.ll ./build/libskip_runtime64.a
	$(CPP) $(OLEVEL) build/out64.ll ./build/libskip_runtime64.a -o build/skia -lrt -lpthread

build/out64.ll: $(SKIP_FILES) build/skc
	mkdir -p build/
	build/skc --preamble prebuild/preamble64.ll --embedded64 $(SKIP_FILES) --export-function-as main=skip_main $(SKFLAGS) --output build/out64.ll

clean:
	rm -Rf build

examples: build/skia
	@echo "=================================================="
	@echo "                   Testing Smol:                  "
	@echo "--------------------------------------------------"
	@echo "file:  ./src/examples/three-vars.smol"
# @echo ""
# @cat ./src/examples/three-vars.smol
# @echo "--------------------------------------------------"
	@cat ./src/examples/three-vars.smol | ./build/skia

	@echo "--------------------------------------------------"
	@echo "file:  ./src/examples/first.smol"
# @echo ""
# @cat ./src/examples/first.smol
# @echo "--------------------------------------------------"
	@cat ./src/examples/first.smol | ./build/skia

	@echo "--------------------------------------------------"
	@echo "file:  ./src/examples/one-fun.smol"
# @echo ""
# @cat ./src/examples/one-fun.smol
# @echo "--------------------------------------------------"
	@cat ./src/examples/one-fun.smol | ./build/skia

	@echo "--------------------------------------------------"
	@echo "file:  ./src/examples/control-flow.smol"
# @echo ""
# @cat ./src/examples/control-flow.smol
# @echo "--------------------------------------------------"
	@cat ./src/examples/control-flow.smol | ./build/skia


	@echo "--------------------------------------------------"
	@echo "file:  ./src/examples/comments.smol"
# @echo ""
# @cat ./src/examples/comments.smol
# @echo "--------------------------------------------------"
	@cat ./src/examples/comments.smol | ./build/skia

	@echo "====================== DONE ======================"
