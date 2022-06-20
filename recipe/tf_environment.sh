#!/bin/bash

set -exuo pipefail

source ${PREFIX}/etc/tensorflow/tf_settings.sh

if [[ "${target_platform}" == osx-* ]]; then
  export LDFLAGS="${LDFLAGS} -lz -framework CoreFoundation -Xlinker -undefined -Xlinker dynamic_lookup"
else
  export LDFLAGS="${LDFLAGS} -lrt"
fi
export PATH="$PWD:$PATH"
export CC=$(basename $CC)
export CXX=$(basename $CXX)
export LIBDIR=$PREFIX/lib
export INCLUDEDIR=$PREFIX/include
export BAZEL_MKL_OPT=""
export BAZEL_OPTS=""
# Set this to something as otherwise, it would include CFLAGS which itself contains a host path and this then breaks bazel's include path validation.
export CC_OPT_FLAGS="-O2"

if [[ ${cuda_compiler_version} != "None" ]]; then
    export GCC_HOST_COMPILER_PATH="${GCC}"
    export GCC_HOST_COMPILER_PREFIX="$(dirname ${GCC})"

    export TF_CUDA_PATHS="${PREFIX},${CUDA_HOME}"
    export TF_NEED_CUDA=1
    export TF_CUDA_VERSION="${cuda_compiler_version}"
    export TF_CUDNN_VERSION="${cudnn}"
    export TF_NCCL_VERSION=$(pkg-config nccl --modversion | grep -Po '\d+\.\d+')

    export LDFLAGS="${LDFLAGS//-Wl,-z,now/-Wl,-z,lazy}"
    export CC_OPT_FLAGS="-march=nocona -mtune=haswell"

    if [[ ${cuda_compiler_version} == 10.* ]]; then
        export TF_CUDA_COMPUTE_CAPABILITIES=sm_35,sm_50,sm_60,sm_62,sm_70,sm_72,sm_75,compute_75
    elif [[ ${cuda_compiler_version} == 11.0* ]]; then
        export TF_CUDA_COMPUTE_CAPABILITIES=sm_35,sm_50,sm_60,sm_62,sm_70,sm_72,sm_75,sm_80,compute_80
    elif [[ ${cuda_compiler_version} == 11.1 ]]; then
        export TF_CUDA_COMPUTE_CAPABILITIES=sm_35,sm_50,sm_60,sm_62,sm_70,sm_72,sm_75,sm_80,sm_86,compute_86
    elif [[ ${cuda_compiler_version} == 11.2 ]]; then
        export TF_CUDA_COMPUTE_CAPABILITIES=sm_35,sm_50,sm_60,sm_62,sm_70,sm_72,sm_75,sm_80,sm_86,compute_86
    else
        echo "unsupported cuda version."
        exit 1
    fi
fi
