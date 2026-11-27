#! /bin/bash

set -exuo pipefail

PY_VER=$($PREFIX/bin/python -c "import sys;print('.'.join(str(v) for v in sys.version_info[:2]))")

# install the whl making sure to use host pip/python if cross-compiling
# With staging/inherit, $SRC_DIR is shared with the staging output
# so tensorflow_pkg/ is directly accessible here.
${PYTHON} -m pip install --no-deps $SRC_DIR/tensorflow_pkg/*-cp${PY_VER/./}-*.whl

sed -i.bak "s/cp312/cp${PY_VER/./}/g" ${SP_DIR}/tensorflow-${PKG_VERSION}.dist-info/WHEEL

# The framework symlink on linux is not deduplication -- it is a correctness
# fix. The wheel's pywrap-built libtensorflow_framework is linked WITHOUT
# tf_framework_version_script.lds, so it dynamically exports its embedded
# MLIR subset (~17k unversioned _ZN4mlir* symbols). Loaded before
# libtensorflow_cc, those exports preempt cc's overlapping (version-script-
# leaked) MLIR exports, splitting cc's MLIR/LLVM between two copies of
# LLVM statics. MLIR compares fltSemantics/TypeIDs by pointer identity, so
# every JIT path then dies with "'llvm.mlir.constant' op attribute and type
# have different float semantics" (XLA autotuner, kernel_gen, even eager
# tf.nn.relu on GPU). The pass-2 lib/ framework IS version-scripted (zero
# MLIR exports); linking the wheel to it keeps each library's MLIR
# self-contained -- the same isolation topology as upstream's pip wheel
# (whose compiler-carrying pywrap exports no MLIR/LLVM at all). Verified on
# an sm_75 GPU: swapping this one file fixes eager relu, XLA JIT, and
# model.fit.
#
# Related, UNVERIFIED (needs an sm_80+ GPU): the Ampere-only TF32/mma.sync
# XLA JIT failure previously documented as a known limitation ("FloatAttr
# does not match expected type of the constant ... mma.sync...f32.tf32 ...
# <null operand!> -> Failed to emit LLVM IR"; workaround:
# tf.config.experimental.enable_tensor_float_32_execution(False)) shares
# this bug family's FloatAttr/float-semantics signature and may be fixed by
# this same change. Re-test on Ampere+ before treating it as an upstream
# XLA bug -- though jax-ml/jax#20154 and libxsmm/tpp-mlir#870 show the same
# signature upstream, so a genuine XLA component is also possible.
#
# Linux ONLY. Do NOT swap the framework dylib on macOS: Mach-O two-level
# namespace binds every undefined symbol to a specific provider image at
# link time, so (a) the ELF preemption bug this fixes cannot occur there,
# and (b) lib_pywrap_tensorflow_common.dylib has mlir references recorded
# against the pywrap-built framework's exports -- pointing it at the
# pass-2 framework (which hides mlir) aborts import with
# "Symbol not found: __ZN4mlir14RewritePattern6anchorEv".
if [[ "$target_platform" == "osx-"* ]]; then
  rm -rf ${SP_DIR}/tensorflow/libtensorflow_cc.2.dylib
  ln -sf ${PREFIX}/lib/libtensorflow_cc.2.dylib ${SP_DIR}/tensorflow/libtensorflow_cc.2.dylib
else
  rm -rf ${SP_DIR}/tensorflow/libtensorflow_cc.so.2
  rm -rf ${SP_DIR}/tensorflow/libtensorflow_framework.so.2
  ln -sf ${PREFIX}/lib/libtensorflow_cc.so.2 ${SP_DIR}/tensorflow/libtensorflow_cc.so.2
  ln -sf ${PREFIX}/lib/libtensorflow_framework.so.2 ${SP_DIR}/tensorflow/libtensorflow_framework.so.2
fi

# The tensorboard package has the proper entrypoint
rm -f ${PREFIX}/bin/tensorboard
