#!/bin/bash

set -ex

# eigen variant, do not build with MKL support
export TF_NEED_MKL=0
export BAZEL_MKL_OPT=""

export PYTHON_BIN_PATH="$PYTHON"
export PYTHON_LIB_PATH="$SP_DIR"

export TF_NEED_CUDA=0
export TF_ENABLE_XLA=0
export TF_NEED_VERBS=0
export TF_NEED_GCP=1
export TF_NEED_KAFKA=0
export TF_NEED_HDFS=0
export TF_NEED_OPENCL_SYCL=0
echo "" | ./configure

# Modern versions of bazel also inject user environment variables in additional
# arguments. This causes the final command line argument length to explode on
# Windows. This can be mitigated by keeping the global build matrix contents to
# the absolute minimum.
BUILD_OPTS="--define=override_eigen_strong_inline=true --experimental_shortened_obj_file_path=true ${BAZEL_MKL_OPT}"
${LIBRARY_BIN}/bazel --batch build -c opt $BUILD_OPTS tensorflow/tools/pip_package:build_pip_package || exit $?

# xref: https://github.com/tensorflow/tensorflow/issues/21886
# xref: https://github.com/tensorflow/tensorflow/issues/6396
# While the build is running, open a shell and type the following:
# export _param_file="/c/users/$USER/_bazel_$USER/xxxxxxxx/execroot/org_tensorflow/bazel-out/x64_windows-opt/bin/tensorflow/python/_pywrap_tensorflow_internal.so-2.params"
# while true; do if [ -f $_param_file ]; then sed -i 's,^/WHOLEARCHIVE:\(.*external.*\),\1,' $_param_file;  sed -i 's,\(.*icuuc.lib\),\/WHOLEARCHIVE:\1,' $_param_file; echo done; break; fi; done
# export _param_file="/c/users/$USER/_bazel_$USER/xxxxxxxx/execroot/org_tensorflow/bazel-out/x64_windows-opt/bin/tensorflow/lite/toco/python/_tensorflow_wrap_toco.so-2.params"
# while true; do if [ -f $_param_file ]; then sed -i 's,^/WHOLEARCHIVE:\(.*external.*\),\1,' $_param_file; echo done; break; else sleep 1; fi; done

PY_TEST_DIR="py_test_dir"
rm -fr ${PY_TEST_DIR}
mkdir -p ${PY_TEST_DIR}
cmd /c "mklink /J ${PY_TEST_DIR}\\tensorflow .\\tensorflow"

./bazel-bin/tensorflow/tools/pip_package/build_pip_package "$PWD/${PY_TEST_DIR}"

PIP_NAME=$(ls ${PY_TEST_DIR}/tensorflow-*.whl)
pip install ${PIP_NAME} --no-deps

# The tensorboard package has the proper entrypoint
rm -f ${PREFIX}/Scripts/tensorboard.exe