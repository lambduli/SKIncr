# SKIncr

SKIncr is a research project on incremental compilation and static analysis based on SKIP.
The gist of the idea is simple, many static-analysis and compilation schemes are abandonned because they are too expensive.
But what if they were incremental? A lot of those schemes would become practical.

# In the repo

You will find a port of the abstract interpreter found in https://books.google.com.co/books/about/Principles_of_Abstract_Interpretation.html?id=Cwk_EAAAQBAJ&redir_esc=y

A few things have been abstracted away in the SKIP version, to be able to work with any domain.

# State of SKIP

The Skip compiler should be open-sourced by the end of january 2023, in the mean time, I included a copy of the compiler that we can later remove.

# INSTALL

Make sure to have clang-10 install on your machine.
```
  make
  make examples
```
