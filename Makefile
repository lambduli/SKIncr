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
	@echo "**************************************************"
	@echo "*** using the forward abstract interpreter:"
	@echo "**************************************************"
	@echo "*** if (n<1) { i = n; while (i!=1) i = i-1; ; }"
	@echo "if (n<1) { i = n; while (i!=1) i = i-1; ; }" | ./build/skia
	@echo "**************************************************"
	@echo "*** ;"
	@echo "**************************************************"
	@echo "*** {}"
	@echo "{}"| ./build/skia
	@echo "**************************************************"
	@echo "*** x = 42;"
	@echo "x = 42;"| ./build/skia
	@echo "**************************************************"
	@echo "*** break;"
	@echo "break;"| ./build/skia
	@echo "**************************************************"
	@echo "*** break; x = 7;"
	@echo "break; x = 7;"| ./build/skia
	@echo "**************************************************"
	@echo "*** x = 7; ; break;"
	@echo "x = 7; ; break; "| ./build/skia
	@echo "**************************************************"
	@echo "*** {}"
	@echo "{}" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=-10-20--40;"
	@echo "x=-10-20--40;" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=1; y=2;"
	@echo "x=1; y=2;" | ./build/skia
	@echo "**************************************************"
	@echo "*** y=x; z=y;"
	@echo "y=x; z=y;" | ./build/skia
	@echo "**************************************************"
	@echo "*** {x=10; ; y=20;}"
	@echo "{x=10; ; y=20;}" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=x"
	@echo "x=x" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=-x"
	@echo "x=-x" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=-y"
	@echo "x=-y" | ./build/skia
	@echo "**************************************************"
	@echo "*** if (0==0) x=-x;"
	@echo "if (0==0) x=-x;" | ./build/skia
	@echo "**************************************************"
	@echo "*** if (0==1) x=-x;"
	@echo "if (0==1) x=-x;" | ./build/skia
	@echo "**************************************************"
	@echo "*** if ((0==0) nand (0==1)) x=-x;"
	@echo "if ((0==0) nand (0==1)) x=-x;" | ./build/skia
	@echo "**************************************************"
	@echo "*** if (1-2<3-4-5) x=-x;"
	@echo "if (1-2<3-4-5) x=-x;" | ./build/skia
	@echo "**************************************************"
	@echo "*** if (x<1) y = 0; else y = 1;"
	@echo "if (x<1) y = 0; else y = 1;" | ./build/skia
	@echo "**************************************************"
	@echo "*** if (x<1) y = 0; else y = 1;"
	@echo "if (x<1) y = 0; else y = 1;" | ./build/skia
	@echo "**************************************************"
	@echo "*** if (x<1) if (x<0) x=1; else if (x<0) { x=2; x=3; } else { x=4; x=5; x=6; }"
	@echo "if (x<1) if (x<0) x=1; else if (x<0) { x=2; x=3; } else { x=4; x=5; x=6; }" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (x<0) x=x;"
	@echo "while (x<0) x=x;" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (x<1) {}"
	@echo "while (x<1) {}" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (x<1) ;"
	@echo "while (x<1) ;" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (x<1) {;}"
	@echo "while (x<1) {;}" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (x<1) {{{{{;}}}}}"
	@echo "while (x<1) {{{{{;}}}}}" | ./build/skia
	@echo "****TODO*** memes exemplles *******************************************"
	@echo "**************************************************"
	@echo "*** while (x<1) {}"
	@echo "while (x<1) {}" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (x<1) x = x + 1;"
	@echo "while (x<1) x = x + 1;" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (x<10) x = x + 1;"
	@echo "while (x<10) x = x + 1;" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (0<1){x = x - 1;} x = 42;"
	@echo "while (0<1){x = x - 1;} x = 42;" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (0<1) {}"
	@echo "while (0<1) {}" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=x-1;while (0<1){x=x-1;if(x<2)break;};"
	@echo "x=x-1;while (0<1){x=x-1;if(x<2)break;};" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=-10; while (x<0) if (x<0) if (0<x) x=-x;"
	@echo "x=-10; while (x<0) if (x<0) if (0<x) x=-x;" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=-10; while (x<0) { x=x-1; break; }; x= 10;"
	@echo "x=-10; while (x<0) { x=x-1; break; }; x= 10;" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=0; while (x<0) { while (x<0) x=x-1; x= 10; }; x= 100;"
	@echo "x=0; while (x<0) { while (x<0) x=x-1; x= 10; }; x= 100;" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=0; while (x<0) { while (x<0) x=x-1; break; }; x= 100;"
	@echo "x=0; while (x<0) { while (x<0) x=x-1; break; }; x= 100;" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=x-1; while (0<1) { x=x-1; if (2 < x) break; };"
	@echo "x=x-1; while (0<1) { x=x-1; if (2 < x) break; };" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=10; while (x>0) x=x-1;"
	@echo "x=10; while (x>0) x=x-1;" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (0<1){ break; x=1; }"
	@echo "while (0<1){ break; x=1; }" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (x!=2) { if (x==0) break; if (x==1) break; }"
	@echo "while (x!=2) { if (x==0) break; if (x==1) break; }" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (0<1) x=x+2;"
	@echo "while (0<1) x=x+2;" |./build/skia
	@echo "**************************************************"
	@echo "*** while (x<100){if (y==0) x=x+3; else x=x+6; y=y+6;}"
	@echo "while (x<100){if (y==0) x=x+3; else x=x+6; y=y+6;}" |./build/skia
	@echo "**************************************************"
	@echo "*** x=1;y=2;if(z<0) z=x; else z=y; if (x==z) x=2; else y=3;"
	@echo "x=1;y=2;if(z<0) z=x; else z=y; if (x==z) x=2; else y=3;" |./build/skia
	@echo "**************************************************"
	@echo "*** x=1;y=2;if(z<0) z=x; else z=y; if ((x==z) nand (y==z)) x=2; else y=3;"
	@echo "x=1;y=2;if(z<0) z=x; else z=y; if ((x==z) nand (y==z)) x=2; else y=3;" |./build/skia
	@echo "**************************************************"
	@echo "*** y=1;if(z<0) z=x; else z=y; if ((x==z) nand (y==z)) x=1; else y=2;"
	@echo "y=1;if(z<0) z=x; else z=y; if ((x==z) nand (y==z)) x=1; else y=2;" |./build/skia
	@echo "**************************************************"
	@echo "*** x=1; if (0<1) x=4;"
	@echo "x=1; if (0<1) x=4;" |./build/skia
	@echo "**************************************************"
	@echo "*** x=1;while (x<1000) x=x+1"
	@echo "x=1;while (x<1000) x=x+1;" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=1;while (x<1000) x=x+2;"
	@echo "x=1;while (x<1000) x=x+2;" | ./build/skia
	@echo "**************************************************"
	@echo "*** while (x<100) { if (y == 0) x=x+3; else  x=x+6; y=y+6; }"
	@echo "while (x<100) { if (y == 0) x=x+3; else  x=x+6; y=y+6; }" |./build/skia
	@echo "**************************************************"
	@echo "*** if ((x+x!=y) nand (y+y!=x)) r=1; else r=3;"
	@echo "if ((x+x!=y) nand (y+y!=x)) r=1; else r=3;" |./build/skia
	@echo "**************************************************"
	@echo "*** if ((x<y nand y<x) nand (x<y nand y<x)) r=1; else r=3;"
	@echo "if ((x<y nand y<x) nand (x<y nand y<x)) r=1; else r=3;" |./build/skia
	@echo "**************************************************"
	@echo "*** x=0; y=0; while (x<100) { x = x + 1; y = y + 1; }"
	@echo "x=0; y=0; while (x<100) { x = x + 1; y = y + 1; }" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=0; y=0; while (x<100) { x = x + 1; y = y + 2; }"
	@echo "x=0; y=0; while (x<100) { x = x + 1; y = y + 2; }" | ./build/skia
	@echo "**************************************************"
	@echo "*** b=0; x=1; while (0<1) { if (b == 0) { b=1; x=0; } else x=x+1; }"
	@echo "b=0; x=1; while (0<1) { if (b == 0) { b=1; x=0; } else x=x+1; }" | ./build/skia
	@echo "**************************************************"
	@echo "*** i=0; while (i<n) i=i+1;"
	@echo "i=0; while (i<n) i=i+1;" | ./build/skia
	@echo "**************************************************"
	@echo "*** s=0; while (0<1) if (s==59) s=0; else s=s+1;"
	@echo "s=0; while (0<1) if (s==59) s=0; else s=s+1;" | ./build/skia
	@echo "**************************************************"
	@echo "*** x=0; c=1; while (x<100) { x = x+c; c=c+c; }"
	@echo "x=0; c=1; while (x<100) { x = x+c; c=c+c; }" | ./build/skia
	@echo "**************************************************"
	@echo "*** end"
