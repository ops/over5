#!/bin/bash

sub_dirs=`find . -name configure.ac | xargs dirname`

for d in $sub_dirs; do
    (cd $d; autoconf)
done
