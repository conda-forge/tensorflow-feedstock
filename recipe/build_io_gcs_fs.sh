#!/bin/bash

set -exuo pipefail

pushd tensorflow-io

./configure.sh

bazel build //tensorflow_io_gcs_filesystem/...
python setup.py bdist_wheel --data bazel-bin --project tensorflow-io-gcs-filesystem
${PYTHON} -m pip install --no-deps dist/*.whl
bazel clean
popd
