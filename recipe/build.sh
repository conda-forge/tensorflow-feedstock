#!/bin/bash

# install using pip from the whl files on PyPI
if [ `uname` == Darwin ]; then
    if [ "$PY_VER" == "2.7" ]; then
        WHL_FILE=https://storage.googleapis.com/tensorflow/mac/cpu/${PKG_NAME}-${PKG_VERSION}-py2-none-any.whl
    else
        WHL_FILE=https://storage.googleapis.com/tensorflow/mac/cpu/${PKG_NAME}-${PKG_VERSION}-py3-none-any.whl
    fi
fi

if [ `uname` == Linux ]; then
    if [ "$PY_VER" == "2.7" ]; then
        WHL_FILE=https://pypi.org/packages/cp27/t/tensorflow/${PKG_NAME}-${PKG_VERSION}-cp27-cp27mu-manylinux1_x86_64.whl
    elif [ "$PY_VER" == "3.6" ]; then
        WHL_FILE=https://pypi.org/packages/cp36/t/tensorflow/${PKG_NAME}-${PKG_VERSION}-cp36-cp36m-manylinux1_x86_64.whl
    elif [ "$PY_VER" == "3.7" ]; then
        WHL_FILE=https://pypi.org/packages/cp37/t/tensorflow/${PKG_NAME}-${PKG_VERSION}-cp37-cp37m-manylinux1_x86_64.whl
    fi
fi

pip install --no-deps $WHL_FILE
