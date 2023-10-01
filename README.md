# SKIncr

To run this version of Skip you need a particular release of LLVM (10). The most portable way to do this is to build a docker image using some variant of the Docker file in the top directory.

In the Dockerfile you may have to change the first line

> FROM  --platform=linux/arm64   ubuntu:20.04

to the right architecture. The above is for a Mac M2 processor.

Then you can build the image with:

> docker build . --tag skip

Once built, you will start the Docker deamon and run the following

> docker run -it -v /Users/jan/SKIncr:/SKIncr skip bash

where "/Users/jan/SKIncr" is the path to your clone of the repo. and "/SKIncr" is the path in the docker image.

This will allow you to edit files on your machine and run the compiler within git.

To build the project

> cd /SKIncr

> make

And to run the example:

>  ./build/skia --print_ir --analyze tests/stdlib.sm tests/good/4/main.sm 

From time to time I have had to muck with the Makefile

> head Makefile
CC=clang-10
CPP=clang++-10
LLC=llc-10

The first two lines depend on your install. These should be good with what is in the image.

If you encounter any issues ping me.


# SKIP

Skip is a language developed and open source by Facebook. The version we are running has been forked and is being revamped. This versions has limited libraries and exceptions are not working. This should be fixed soonish.

Documentation on skip is at : skiplang.com