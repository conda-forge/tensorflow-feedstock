#! /bin/bash

set -exuo pipefail
if [[ "${cuda_compiler_version}" == 12* ]]; then
    # cuda-compat is used for providing libcuda.so.1 temporarily
    cp $PREFIX/cuda-compat/libcuda.so.1 $PREFIX/lib/libcuda.so.1
fi

# install the whl making sure to use host pip/python if cross-compiling
${PYTHON} -m pip install --no-deps $SRC_DIR/tensorflow_pkg/*.whl

# The tensorboard package has the proper entrypoint
rm -f ${PREFIX}/bin/tensorboard

if [[ "${cuda_compiler_version}" == 12* ]]; then
    # This was needed to load in the cuda symbols correctly temporarily
    # https://github.com/conda-forge/tensorflow-feedstock/pull/408#issuecomment-2585259178
    rm -f $PREFIX/lib/libcuda.so.1
fi
