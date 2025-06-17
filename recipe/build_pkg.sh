#! /bin/bash

set -exuo pipefail

# install the whl making sure to use host pip/python if cross-compiling
${PYTHON} -m pip install --no-deps $SRC_DIR/tensorflow_pkg/*.whl

if [[ "$target_platform" == "osx-"* ]]; then
  rm -rf ${SP_DIR}/tensorflow/libtensorflow.2.dylib
  rm -rf ${SP_DIR}/tensorflow/libtensorflow_cc.2.dylib
  ln -sf ${PREFIX}/lib/libtensorflow.2.dylib ${SP_DIR}/tensorflow/libtensorflow.2.dylib
  ln -sf ${PREFIX}/lib/libtensorflow_cc.2.dylib ${SP_DIR}/tensorflow/libtensorflow_cc.2.dylib
else
  rm -rf ${SP_DIR}/tensorflow/libtensorflow.so.2
  rm -rf ${SP_DIR}/tensorflow/libtensorflow_cc.so.2
  ln -sf ${PREFIX}/lib/libtensorflow.so.2 ${SP_DIR}/tensorflow/libtensorflow.so.2
  ln -sf ${PREFIX}/lib/libtensorflow_cc.so.2 ${SP_DIR}/tensorflow/libtensorflow_cc.so.2
fi

# The tensorboard package has the proper entrypoint
rm -f ${PREFIX}/bin/tensorboard
