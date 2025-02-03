#!/bin/bash

set -ex

if [[ "$CI" == "github_actions" ]]; then
  export CPU_COUNT=4
fi

# Make libprotobuf-python-headers visible for pybind11_protobuf
# These files will be deleted at the end of the build.
mkdir -p $PREFIX/include/python
cp -r $PREFIX/include/google $PREFIX/include/python/

sed -i "s;@@PREFIX@@;$PREFIX;" third_party/pybind11_protobuf/0001-Add-Python-include-path.patch
sed -i "s;@@PY_VER@@;$PY_VER;" third_party/pybind11_protobuf/0001-Add-Python-include-path.patch

export PATH="$PWD:$PATH"
export CC=$(basename $CC)
export CXX=$(basename $CXX)
export LIBDIR=$PREFIX/lib
export INCLUDEDIR=$PREFIX/include

export TF_PYTHON_VERSION=$PY_VER

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
  astor_archive
  astunparse_archive
  boringssl
  com_github_googlecloudplatform_google_cloud_cpp
  com_github_grpc_grpc
  com_google_absl
  com_google_protobuf
  curl
  cython
  dill_archive
  flatbuffers
  gast_archive
  gif
  icu
  libjpeg_turbo
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
# Set this to something as otherwise, it would include CFLAGS which itself contains a host path and this then breaks bazel's include path validation.
export CC_OPT_FLAGS="-O2"

# Quick debug:
# cp -r ${RECIPE_DIR}/build.sh . && bazel clean && bash -x build.sh --logging=6 | tee log.txt
# Dependency graph:
# bazel query 'deps(//tensorflow/tools/lib_package:libtensorflow)' --output graph > graph.in
if [[ "${target_platform}" == osx-* ]]; then
  export LDFLAGS="${LDFLAGS} -lz -framework CoreFoundation -Xlinker -undefined -Xlinker dynamic_lookup"
else
  export LDFLAGS="${LDFLAGS} -lrt"
fi

if [[ ${cuda_compiler_version} != "None" ]]; then
    export LDFLAGS="${LDFLAGS} -lcusparse"
    export GCC_HOST_COMPILER_PATH="${GCC}"
    export GCC_HOST_COMPILER_PREFIX="$(dirname ${GCC})"

    export TF_NEED_CUDA=1
    export TF_CUDA_VERSION="${cuda_compiler_version}"
    export TF_CUDNN_VERSION="${cudnn}"
    export HERMETIC_CUDA_VERSION="${cuda_compiler_version}"
    export HERMETIC_CUDNN_VERSION="${cudnn}"
    export TF_NCCL_VERSION=$(pkg-config nccl --modversion | grep -Po '\d+\.\d+')

    export LDFLAGS="${LDFLAGS//-Wl,-z,now/-Wl,-z,lazy}"
    export CC_OPT_FLAGS="-march=nocona -mtune=haswell"

    if [[ ${cuda_compiler_version} == 11.8 ]]; then
        export HERMETIC_CUDA_COMPUTE_CAPABILITIES=sm_35,sm_50,sm_60,sm_62,sm_70,sm_72,sm_75,sm_80,sm_86,sm_87,sm_89,sm_90,compute_90
        export TF_CUDA_PATHS="${PREFIX},${CUDA_HOME}"
    elif [[ "${cuda_compiler_version}" == 12* ]]; then
        export HERMETIC_CUDA_COMPUTE_CAPABILITIES=sm_60,sm_70,sm_75,sm_80,sm_86,sm_89,sm_90,compute_90
        export CUDNN_INSTALL_PATH=$PREFIX
        export NCCL_INSTALL_PATH=$PREFIX
        export CUDA_HOME="${BUILD_PREFIX}/targets/x86_64-linux"
        export TF_CUDA_PATHS="${BUILD_PREFIX}/targets/x86_64-linux,${PREFIX}/targets/x86_64-linux"
        # XLA can only cope with a single cuda header include directory, merge both
        rsync -a ${PREFIX}/targets/x86_64-linux/include/ ${BUILD_PREFIX}/targets/x86_64-linux/include/

        # Although XLA supports a non-hermetic build, it still tries to find headers in the hermetic locations.
        # We do this in the BUILD_PREFIX to not have any impact on the resulting jaxlib package.
        # Otherwise, these copied files would be included in the package.
        rm -rf ${BUILD_PREFIX}/targets/x86_64-linux/include/third_party
        mkdir -p ${BUILD_PREFIX}/targets/x86_64-linux/include/third_party/gpus/cuda/extras/CUPTI
        cp -r ${PREFIX}/targets/x86_64-linux/include ${BUILD_PREFIX}/targets/x86_64-linux/include/third_party/gpus/cuda/
        cp -r ${PREFIX}/targets/x86_64-linux/include ${BUILD_PREFIX}/targets/x86_64-linux/include/third_party/gpus/cuda/extras/CUPTI/
        mkdir -p ${BUILD_PREFIX}/targets/x86_64-linux/include/third_party/gpus/cudnn
        cp ${PREFIX}/include/cudnn*.h ${BUILD_PREFIX}/targets/x86_64-linux/include/third_party/gpus/cudnn/
        mkdir -p ${BUILD_PREFIX}/targets/x86_64-linux/include/third_party/nccl
        cp ${PREFIX}/include/nccl.h ${BUILD_PREFIX}/targets/x86_64-linux/include/third_party/nccl/
        rsync -a ${PREFIX}/targets/x86_64-linux/lib/ ${BUILD_PREFIX}/targets/x86_64-linux/lib/
        ln -s ${BUILD_PREFIX}/bin/fatbinary ${BUILD_PREFIX}/targets/x86_64-linux/bin/fatbinary
        ln -s ${BUILD_PREFIX}/bin/nvlink ${BUILD_PREFIX}/targets/x86_64-linux/bin/nvlink
        ln -s ${BUILD_PREFIX}/bin/ptxas ${BUILD_PREFIX}/targets/x86_64-linux/bin/ptxas

        export LOCAL_CUDA_PATH="${BUILD_PREFIX}/targets/x86_64-linux"
        export LOCAL_CUDNN_PATH="${PREFIX}"
        export LOCAL_NCCL_PATH="${PREFIX}"

        # hmaarrfk -- 2023/12/30
        # This logic should be safe to keep in even when the underlying issue is resolved
        # xref: https://github.com/conda-forge/cuda-nvcc-impl-feedstock/issues/9
        if [[ -x ${BUILD_PREFIX}/nvvm/bin/cicc ]]; then
            cp ${BUILD_PREFIX}/nvvm/bin/cicc ${BUILD_PREFIX}/bin/cicc
        fi

        # Needs GCC 13+
        echo "build --define=xnn_enable_avxvnniint8=false" >> .bazelrc

        # cuda-compat is used for providing libcuda.so.1 temporarily
        # https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/tf_sig_build_dockerfiles/setup.cuda.sh#L28
        ln -s ${BUILD_PREFIX}/targets/x86_64-linux/lib/stubs/libcuda.so ${PREFIX}/lib/libcuda.so.1
    else
        echo "unsupported cuda version."
        exit 1
    fi
else
    export TF_NEED_CUDA=0
fi

source ${RECIPE_DIR}/gen-bazel-toolchain.sh

if [[ "${target_platform}" == "osx-64" ]]; then
  # Tensorflow doesn't cope yet with an explicit architecture (darwin_x86_64) on osx-64 yet.
  TARGET_CPU=darwin
  # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
  export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

# Get rid of unwanted defaults
sed -i -e "/PROTOBUF_INCLUDE_PATH/c\ " .bazelrc
sed -i -e "/PREFIX/c\ " .bazelrc
# Ensure .bazelrc ends in a newline
echo "" >> .bazelrc

if [[ "${target_platform}" == "osx-arm64" ]]; then
  echo "build --config=macos_arm64" >> .bazelrc
  # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
  export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi
export TF_ENABLE_XLA=1
export BUILD_TARGET="//tensorflow/tools/pip_package:wheel //tensorflow/tools/lib_package:libtensorflow //tensorflow:libtensorflow_cc${SHLIB_EXT}"

# Python settings
export PYTHON_BIN_PATH=${PYTHON}
export PYTHON_LIB_PATH=${SP_DIR}
export USE_DEFAULT_PYTHON_LIB_PATH=1

# additional settings
export TF_NEED_OPENCL=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_COMPUTECPP=0
export TF_CUDA_CLANG=0
if [[ "${target_platform}" == linux-* ]]; then
  export TF_NEED_CLANG=0
fi
export TF_NEED_TENSORRT=0
export TF_NEED_ROCM=0
export TF_NEED_MPI=0
export TF_DOWNLOAD_CLANG=0
export TF_SET_ANDROID_WORKSPACE=0
export TF_CONFIGURE_IOS=0


#bazel clean --expunge
#bazel shutdown

./configure

# Remove legacy flags set by configure that conflicts with CUDA 12's multi-directory approach.
if [[ "${cuda_compiler_version}" == 12* ]]; then
    sed -i '/CUDA_TOOLKIT_PATH/d' .tf_configure.bazelrc
fi

if [[ "${build_platform}" == linux-* ]]; then
  $RECIPE_DIR/add_py_toolchain.sh
fi

cat >> .bazelrc <<EOF
build --crosstool_top=//custom_toolchain:toolchain
build --@local_config_cuda//cuda:override_include_cuda_libs=true
build --logging=6
build --verbose_failures
build --define=PREFIX=${PREFIX}
build --define=PROTOBUF_INCLUDE_PATH=${PREFIX}/include
build --cpu=${TARGET_CPU}
build --local_cpu_resources=${CPU_COUNT}
EOF

# Update TF lite schema with latest flatbuffers version
pushd tensorflow/compiler/mlir/lite/schema
flatc --cpp --gen-object-api schema.fbs
popd
rm -f tensorflow/lite/schema/conversion_metadata_generated.h
rm -f tensorflow/lite/experimental/acceleration/configuration/configuration_generated.h
rm -f tensorflow/lite/acceleration/configuration/configuration_generated.h
sed -ie "s;BUILD_PREFIX;${BUILD_PREFIX};g" tensorflow/tools/pip_package/build_pip_package.py

# build using bazel
bazel ${BAZEL_OPTS} build ${BUILD_TARGET}

# build a whl file
mkdir -p $SRC_DIR/tensorflow_pkg
cp bazel-bin/tensorflow/tools/pip_package/wheel_house/tensorflow*.whl $SRC_DIR/tensorflow_pkg

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
rsync -r --chmod=D777,F666 --include '*/' --include '*.h' --include '*.inc' --exclude '*' third_party/xla/third_party/tsl/ $SRC_DIR/libtensorflow_cc_output/include/
rsync -r --chmod=D777,F666 --include '*/' --include '*' --exclude '*.cc' third_party/ $SRC_DIR/libtensorflow_cc_output/include/tensorflow/third_party/
rsync -r --chmod=D777,F666 --include '*/' --include '*' --exclude '*.txt' bazel-work/external/eigen_archive/Eigen/ $SRC_DIR/libtensorflow_cc_output/include/tensorflow/third_party/Eigen/
rsync -r --chmod=D777,F666 --include '*/' --include '*' --exclude '*.txt' bazel-work/external/eigen_archive/unsupported/ $SRC_DIR/libtensorflow_cc_output/include/tensorflow/third_party/unsupported/
pushd $SRC_DIR/libtensorflow_cc_output
  tar cf ../libtensorflow_cc_output.tar .
popd
rm -r $SRC_DIR/libtensorflow_cc_output

bazel clean

# This was only needed for protobuf_python
rm -rf $PREFIX/include/python
rm -f $PREFIX/lib/libcuda.so.1
