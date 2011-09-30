#!/bin/bash

ASAN="../asan_clang_Linux/bin/clang++ -O1 -g -fasan"
FILTER="../scripts/asan_symbolize.py /"

for source in example_*.cc; do
  name=`echo $source | sed 's/example_//g; s/\.cc$//g'`
  echo $name
  wiki="Example$name.wiki"
  rm -f $wiki
  printf "#summary Example: $name\n" >> $wiki
  printf "{{{\n"                     >> $wiki
  cat $source                        >> $wiki
  printf "}}}\n"                     >> $wiki

  printf "{{{\n"                     >> $wiki
  printf "clang++ -O1 -fasan $source\n" >> $wiki
  printf "./a.out\n"                 >> $wiki
  printf "}}}\n"                     >> $wiki

  $ASAN $source
  printf "{{{\n"                     >> $wiki
  ./a.out 2>&1 | $FILTER | c++filt   >> $wiki
  printf "}}}\n"                     >> $wiki
  rm -f ./a.out
done
