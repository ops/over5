#!/bin/bash

sub_dirs=`find . -name configure.ac | xargs dirname`

for d in $sub_dirs; do
    (echo Processing `basename $d`; cd $d; autoconf)
done
