#!/bin/bash

set -exuo pipefail

if [[ "${cuda_compiler_version}" == 12* ]]; then
    # cuda-compat is used for providing libcuda.so.1 temporarily
    ln -s ${BUILD_PREFIX}/targets/x86_64-linux/lib/stubs/libcuda.so ${PREFIX}/lib/libcuda.so.1
fi

pushd tensorflow-estimator

WHEEL_DIR=${PWD}/wheel_dir
mkdir -p ${WHEEL_DIR}
if [[ "${build_platform}" == linux-* ]]; then
  $RECIPE_DIR/add_py_toolchain.sh
fi
bazel build tensorflow_estimator/tools/pip_package:build_pip_package
bazel-bin/tensorflow_estimator/tools/pip_package/build_pip_package ${WHEEL_DIR}
${PYTHON} -m pip install --no-deps ${WHEEL_DIR}/*.whl
bazel clean
popd

if [[ "${cuda_compiler_version}" == 12* ]]; then
    # This was needed to load in the cuda symbols correctly temporarily
    # https://github.com/conda-forge/tensorflow-feedstock/pull/408#issuecomment-2585259178
    rm -f $PREFIX/lib/libcuda.so.1
fi
