#!/bin/bash

# install using pip from the whl file provided by Google

if [ `uname` == Darwin ]; then
    if [ "$PY_VER" == "2.7" ]; then
        pip install --no-deps https://storage.googleapis.com/tensorflow/mac/cpu/tensorflow-${PKG_VERSION}-py2-none-any.whl
    else
        pip install --no-deps https://storage.googleapis.com/tensorflow/mac/cpu/tensorflow-${PKG_VERSION}-py3-none-any.whl
    fi
fi

if [ `uname` == Linux ]; then
    # Build tensorflow from source using cmake
    rm -rf build
    mkdir -p build
    cd build

    # The search path must be set so that zlib.h can be found
    export CFLAGS="${CFLAGS} -I${PREFIX}/include"
    # The rt library must be included during linking as the clock_ functions
    # are not part of the main glibc library in older versions (prior to 2.17)
    cmake \
        -DCMAKE_EXE_LINKER_FLAGS=-lrt \
        -DCMAKE_BUILD_TYPE=Release ../tensorflow/contrib/cmake
    make -j${CPU_COUNT} tf_python_build_pip_package

    pip install --no-deps ./tf_python/dist/*.whl
fi
