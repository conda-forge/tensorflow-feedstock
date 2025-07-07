#!/bin/bash

set -exuo pipefail

pushd tensorflow-estimator

WHEEL_DIR=${PWD}/wheel_dir${PY_VER}
mkdir -p ${WHEEL_DIR}
if [[ "${build_platform}" == linux-* ]]; then
  $RECIPE_DIR/add_py_toolchain.sh
fi
bazel build tensorflow_estimator/tools/pip_package:build_pip_package
bazel-bin/tensorflow_estimator/tools/pip_package/build_pip_package ${WHEEL_DIR}
${PYTHON} -m pip install --no-deps ${WHEEL_DIR}/*.whl
bazel clean
popd
