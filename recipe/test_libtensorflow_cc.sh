#!/bin/bash

set -exuo pipefail

$CXX -std=c++14 -o test_cc -L${PREFIX}/lib/ -ltensorflow_cc -ltensorflow_framework -lrt -I${PREFIX}/include/ test_cc.cc
./test_cc
