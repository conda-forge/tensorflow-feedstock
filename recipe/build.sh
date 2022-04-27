#!/bin/bash

set -ex

if [[ "${target_platform}" != "${build_platform}" ]]; then
  if [ ! -d "llvm-build" ]; then
    conda create -y -p llvm-build llvmdev=14.0.0.tf280_55c71c9eac9b mlir=14.0.0.tf280_55c71c9eac9b -c conda-forge/label/llvm_tf -c conda-forge/label/mlir_tf
    cp -r llvm-build/bin/mlir-opt $BUILD_PREFIX/bin/
    cp -r llvm-build/bin/mlir-reduce $BUILD_PREFIX/bin/
    cp -r llvm-build/bin/mlir-tblgen $BUILD_PREFIX/bin/
    cp -r llvm-build/bin/mlir-linalg-ods-yaml-gen $BUILD_PREFIX/bin/
    cp -r llvm-build/include/llvm $BUILD_PREFIX/include/
    cp -r llvm-build/include/llvm-c $BUILD_PREFIX/include/
    cp -r llvm-build/include/mlir $BUILD_PREFIX/include/
    cp -r llvm-build/lib/libMLIR* $BUILD_PREFIX/lib
    cp -r llvm-build/lib/libLLVM* $BUILD_PREFIX/lib
  fi
fi

# The patch doesn't set the executable flag correctly.
chmod +x tensorflow/tools/pip_package/concat_licenses.sh

python $RECIPE_DIR/generate_llvm.py

export PATH="$PWD:$PATH"
export CC=$(basename $CC)
export CXX=$(basename $CXX)
export LIBDIR=$PREFIX/lib
export INCLUDEDIR=$PREFIX/include

# Upstream docstring for TF_SYSTEM_LIBS in:
# https://github.com/tensorflow/tensorflow/blob/v{{ version }}/third_party/systemlibs/syslibs_configure.bzl
#   * `TF_SYSTEM_LIBS`: list of third party dependencies that should use
#      the system version instead
#
# To avoid bazel installing lots of vendored (python) packages,
# we need to install these packages through meta.yaml and then
# tell bazel to use them. Note that the names don't necessarily
# match PyPI or conda, but are defined in:
# https://github.com/tensorflow/tensorflow/blob/v{{ version }}/tensorflow/workspace<i>.bzl

# Exceptions and TODOs:
# Needs a bazel build:
# com_google_absl
# Build failures in tensorflow/core/platform/s3/aws_crypto.cc
# boringssl (i.e. system openssl)
# Most importantly: Write a patch that uses system LLVM libs for sure as well as MLIR and oneDNN/mkldnn
# TODO(check):
# absl_py
# com_github_googleapis_googleapis
# com_github_googlecloudplatform_google_cloud_cpp
# Needs c++17, try on linux
#  com_googlesource_code_re2
export TF_SYSTEM_LIBS="
  absl_py
  astor_archive
  astunparse_archive
  boringssl
  com_github_googlecloudplatform_google_cloud_cpp
  com_github_grpc_grpc
  com_google_protobuf
  curl
  cython
  dill_archive
  flatbuffers
  gast_archive
  gif
  icu
  libjpeg_turbo
  mkl_dnn_v1
  nsync
  org_sqlite
  png
  pybind11
  snappy
  zlib
  "
sed -i -e "s/GRPCIO_VERSION/${grpc_cpp}/" tensorflow/tools/pip_package/setup.py

# do not build with MKL support
export TF_NEED_MKL=0
export BAZEL_MKL_OPT=""

mkdir -p ./bazel_output_base
export BAZEL_OPTS=""
# We need to pass in something here to get past ./configure.
# This shouldn't be the host CFLAGS as these are also passed to the build commands.
export CC_OPT_FLAGS="-g0"

# Quick debug:
# cp -r ${RECIPE_DIR}/build.sh . && bazel clean && bash -x build.sh --logging=6 | tee log.txt
# Dependency graph:
# bazel query 'deps(//tensorflow/tools/lib_package:libtensorflow)' --output graph > graph.in
if [[ "${target_platform}" == osx-* ]]; then
  export LDFLAGS="${LDFLAGS} -lz -framework CoreFoundation -Xlinker -undefined -Xlinker dynamic_lookup"
else
  export LDFLAGS="${LDFLAGS} -lrt"
fi

source ${RECIPE_DIR}/gen-bazel-toolchain.sh

if [[ "${target_platform}" == "osx-64" ]]; then
  # Tensorflow doesn't cope yet with an explicit architecture (darwin_x86_64) on osx-64 yet.
  TARGET_CPU=darwin
fi

BUILD_OPTS="
    --crosstool_top=//custom_toolchain:toolchain
    --logging=6
    --verbose_failures
    --config=opt
    --define=PREFIX=${PREFIX}
    --define=PROTOBUF_INCLUDE_PATH=${PREFIX}/include
    --config=noaws
    --cpu=${TARGET_CPU}"
# If you really want to see what is executed, add --subcommands
# BUILD_OPTS="${BUILD_OPTS} --subcommands"
# If your local RAM is not sufficient
# BUILD_OPTS="${BUILD_OPTS} --local_cpu_resources=1"

if [[ "${target_platform}" == "osx-arm64" ]]; then
  BUILD_OPTS="${BUILD_OPTS} --config=macos_arm64"
fi
export TF_ENABLE_XLA=0
export BUILD_TARGET="//tensorflow/tools/pip_package:build_pip_package //tensorflow/tools/lib_package:libtensorflow //tensorflow:libtensorflow_cc${SHLIB_EXT}"

# Python settings
export PYTHON_BIN_PATH=${PYTHON}
export PYTHON_LIB_PATH=${SP_DIR}
export USE_DEFAULT_PYTHON_LIB_PATH=1

# additional settings
export TF_NEED_OPENCL=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_COMPUTECPP=0
export TF_NEED_CUDA=0
export TF_CUDA_CLANG=0
export TF_NEED_TENSORRT=0
export TF_NEED_ROCM=0
export TF_NEED_MPI=0
export TF_DOWNLOAD_CLANG=0
export TF_SET_ANDROID_WORKSPACE=0
export TF_CONFIGURE_IOS=0

# Get rid of unwanted defaults
sed -i -e "/PROTOBUF_INCLUDE_PATH/c\ " .bazelrc
sed -i -e "/PREFIX/c\ " .bazelrc


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

bazel clean --expunge
bazel shutdown

./configure

# build using bazel
bazel ${BAZEL_OPTS} build ${BUILD_OPTS} '//tensorflow/core/kernels:libtfkernel_all_kernels.so'

# build a whl file
mkdir -p $SRC_DIR/tensorflow_pkg
bash -x bazel-bin/tensorflow/tools/pip_package/build_pip_package $SRC_DIR/tensorflow_pkg

# Build libtensorflow(_cc)
cp $SRC_DIR/bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz $SRC_DIR
mkdir -p $SRC_DIR/libtensorflow_cc_output/lib
if [[ "${target_platform}" == osx-* ]]; then
  cp -RP bazel-bin/tensorflow/libtensorflow_cc.* $SRC_DIR/libtensorflow_cc_output/lib/
  cp -RP bazel-bin/tensorflow/libtensorflow_framework.* $SRC_DIR/libtensorflow_cc_output/lib/
else
  cp -d bazel-bin/tensorflow/libtensorflow_cc.so* $SRC_DIR/libtensorflow_cc_output/lib/
  cp -d bazel-bin/tensorflow/libtensorflow_framework.so* $SRC_DIR/libtensorflow_cc_output/lib/
  cp -d $SRC_DIR/libtensorflow_cc_output/lib/libtensorflow_framework.so.2 $SRC_DIR/libtensorflow_cc_output/lib/libtensorflow_framework.so
fi
# Make writable so patchelf can do its magic
chmod u+w $SRC_DIR/libtensorflow_cc_output/lib/libtensorflow*

mkdir -p $SRC_DIR/libtensorflow_cc_output/include/tensorflow
rsync -r --chmod=D777,F666 --exclude '_solib*' --exclude '_virtual_includes/' --exclude 'pip_package/' --exclude 'lib_package/' --include '*/' --include '*.h' --include '*.inc' --exclude '*' bazel-bin/ $SRC_DIR/libtensorflow_cc_output/include
rsync -r --chmod=D777,F666 --include '*/' --include '*.h' --include '*.inc' --exclude '*' tensorflow/cc $SRC_DIR/libtensorflow_cc_output/include/tensorflow/
rsync -r --chmod=D777,F666 --include '*/' --include '*.h' --include '*.inc' --exclude '*' tensorflow/core $SRC_DIR/libtensorflow_cc_output/include/tensorflow/
rsync -r --chmod=D777,F666 --include '*/' --include '*' --exclude '*.cc' third_party/ $SRC_DIR/libtensorflow_cc_output/include/third_party/
rsync -r --chmod=D777,F666 --include '*/' --include '*' --exclude '*.txt' bazel-work/external/eigen_archive/Eigen/ $SRC_DIR/libtensorflow_cc_output/include/Eigen/
rsync -r --chmod=D777,F666 --include '*/' --include '*' --exclude '*.txt' bazel-work/external/eigen_archive/unsupported/ $SRC_DIR/libtensorflow_cc_output/include/unsupported/
pushd $SRC_DIR/libtensorflow_cc_output
  tar cf ../libtensorflow_cc_output.tar .
popd
rm -r $SRC_DIR/libtensorflow_cc_output

cp bazel-bin/tensorflow/tools/pip_package/THIRD_PARTY_TF_PY_LICENSES .

bazel clean
