#!/bin/bash

set -ex

if [[ "$target_platform" == linux* ]]; then	
# revert osx

if [[ "$target_platform" == "osx-64" ]]; then
  export CC=clang
  export CXX=clang++
fi

export PATH="$PWD:$PATH"
export CC=$(basename $CC)
export CXX=$(basename $CXX)
export LIBDIR=$PREFIX/lib
export INCLUDEDIR=$PREFIX/include

export TF_SYSTEM_LIBS="llvm,zlib_archive,curl,nsync"

# do not build with MKL support
export TF_NEED_MKL=0
export BAZEL_MKL_OPT=""

mkdir -p ./bazel_output_base
export BAZEL_OPTS="--batch "

# do not build with MKL support
export TF_NEED_MKL=0
export BAZEL_MKL_OPT=""

mkdir -p ./bazel_output_base
export BAZEL_OPTS="--batch "

echo "#!/bin/bash"                                > compiler-wrapper
echo "export C_INCLUDE_PATH=$PREFIX/include"     >> compiler-wrapper
echo "export CPLUS_INCLUDE_PATH=$PREFIX/include" >> compiler-wrapper
echo "export CONDA_BUILD_SYSROOT=$CONDA_BUILD_SYSROOT"  >> compiler-wrapper
echo "export MACOSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET" >> compiler-wrapper
chmod +x "compiler-wrapper"
cp compiler-wrapper $CC
cp compiler-wrapper $CXX
echo "exec $BUILD_PREFIX/bin/$CC -L$PREFIX/lib  \"\$@\" -Wno-unused-command-line-argument"  >> $CC
echo "exec $BUILD_PREFIX/bin/$CXX -L$PREFIX/lib \"\$@\" -Wno-unused-command-line-argument"  >> $CXX

if [[ "$target_platform" == "osx-64" ]]; then
    # set up bazel config file for conda provided clang toolchain
    cp -r ${RECIPE_DIR}/custom_clang_toolchain .
    pushd custom_clang_toolchain
    cp  ../$CC cc_wrapper.sh
    sed -e "s:\${PREFIX}:${BUILD_PREFIX}:" \
        -e "s:\${LD}:${LD}:" \
        -e "s:\${NM}:${NM}:" \
        -e "s:\${STRIP}:${STRIP}:" \
        -e "s:\${LIBTOOL}:${LIBTOOL}:" \
        -e "s:\${CONDA_BUILD_SYSROOT}:${CONDA_BUILD_SYSROOT}:" \
        CROSSTOOL.template > CROSSTOOL
    popd
    export BAZEL_USE_CPP_ONLY_TOOLCHAIN=1
    BUILD_OPTS="
        --crosstool_top=//custom_clang_toolchain:toolchain
        --verbose_failures
        ${BAZEL_MKL_OPT}
        --config=opt"
    export TF_ENABLE_XLA=0
	export BUILD_TARGET="//tensorflow/tools/pip_package:build_pip_package"
else
    # Linux
    # the following arguments are useful for debugging
    #    --logging=6
    #    --subcommands

    # Set compiler and linker flags as bazel does not account for CFLAGS,
    # CXXFLAGS and LDFLAGS.
    BUILD_OPTS="
    --copt=-march=nocona
    --copt=-mtune=haswell
    --copt=-ftree-vectorize
    --copt=-fPIC
    --copt=-fstack-protector-strong
    --copt=-O2
    --cxxopt=-fvisibility-inlines-hidden
    --cxxopt=-fmessage-length=0
    --linkopt=-zrelro
    --linkopt=-znow
    --linkopt=-lrt
    --verbose_failures
    ${BAZEL_MKL_OPT}
    --config=opt"
    export TF_ENABLE_XLA=1
	export BUILD_TARGET="//tensorflow/tools/pip_package:build_pip_package //tensorflow:libtensorflow.so //tensorflow:libtensorflow_cc.so"
fi

# Bazel install
export BAZEL_VERSION=0.29.1
export BAZEL_OS=$(uname | tr '[:upper:]' '[:lower:]')
curl -sSOL https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-${BAZEL_OS}-x86_64.sh
sudo bash -e bazel-${BAZEL_VERSION}-installer-${BAZEL_OS}-x86_64.sh
bazel version

# Python settings
export PYTHON_BIN_PATH=${PYTHON}
export PYTHON_LIB_PATH=${SP_DIR}
export USE_DEFAULT_PYTHON_LIB_PATH=1

# additional settings
export CC_OPT_FLAGS="-march=nocona -mtune=haswell"
export TF_NEED_IGNITE=1
export TF_NEED_OPENCL=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_CUDA=0
export TF_NEED_ROCM=0
export TF_NEED_MPI=0
export TF_DOWNLOAD_CLANG=0
export TF_SET_ANDROID_WORKSPACE=0
./configure

# build using bazel
bazel ${BAZEL_OPTS} build ${BUILD_OPTS} ${BUILD_TARGET}

# build a whl file
mkdir -p $SRC_DIR/tensorflow_pkg
bazel-bin/tensorflow/tools/pip_package/build_pip_package $SRC_DIR/tensorflow_pkg

fi
