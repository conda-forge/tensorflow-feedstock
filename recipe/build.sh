#!/bin/bash

set -exuo pipefail

# Quick debug:
# cp -r ${RECIPE_DIR}/build.sh . && bazel clean && bash -x build.sh --logging=6 | tee log.txt
# Dependency graph:
# bazel query 'deps(//tensorflow/tools/lib_package:libtensorflow)' --output graph > graph.in
export PYTHONUNBUFFERED=1

# Use pre-built LLVM and MLIR
cp -r $PREFIX/share/llvm_for_tf llvm-project
# See https://github.com/tensorflow/tensorflow/blob/3f878cff5b698b82eea85db2b60d65a2e320850e/third_party/llvm/setup.bzl#L6
echo 'llvm_targets = ["AArch64", "AMDGPU", "ARM", "NVPTX", "PowerPC", "RISCV", "SystemZ", "X86"]' > llvm-project/llvm/targets.bzl

# Query immediately before any configuration settings are set.
bazel query 'deps(//tensorflow/tools/pip_package:build_pip_package)' --output graph > graph.in

# Ensure we persist the setting across multiple tensorflow artefacts.
mkdir -p ${PREFIX}/etc/tensorflow
cp ${RECIPE_DIR}/tf_environment.sh ${RECIPE_DIR}/tf_settings.sh ${PREFIX}/etc/tensorflow
source ${RECIPE_DIR}/tf_environment.sh

source gen-bazel-toolchain

if [[ "${target_platform}" == "osx-64" ]]; then
  # Tensorflow doesn't cope yet with an explicit architecture (darwin_x86_64) on osx-64 yet.
  export TARGET_CPU=darwin
fi

# If you really want to see what is executed, add --subcommands
export BUILD_OPTS="
    --crosstool_top=//bazel_toolchain:toolchain
    --logging=6
    --verbose_failures
    --config=opt
    --define=PREFIX=${PREFIX}
    --define=PROTOBUF_INCLUDE_PATH=${PREFIX}/include
    --config=noaws
    --cpu=${TARGET_CPU}
    --local_cpu_resources=${CPU_COUNT}"

if [[ "${target_platform}" == "osx-arm64" ]]; then
  export BUILD_OPTS="${BUILD_OPTS} --config=macos_arm64"
fi
# General idea:
# * Query all dependencies of the pip_package
# * Filter all targets that are in e.g. //tensorflow/core
# * Find out which of these are cc_library, then build those
# * Extend the above step to build more than just cc_library

# Python settings
export PYTHON_BIN_PATH=${BUILD_PREFIX}/bin/python
export PYTHON_LIB_PATH=$(python -c 'import site; print(site.getsitepackages()[0])')
export USE_DEFAULT_PYTHON_LIB_PATH=1

# Get rid of unwanted defaults
sed -i -e "/PROTOBUF_INCLUDE_PATH/c\ " .bazelrc
sed -i -e "/PREFIX/c\ " .bazelrc


./configure
python $RECIPE_DIR/build_cache.py

bazel clean
