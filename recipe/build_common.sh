#!/bin/bash

set -ex

if [[ "${CI:-}" == "github_actions" ]]; then
  export CPU_COUNT=4
fi

# hmaarrfk - 2025/07/06
# Make libprotobuf-python-headers visible for pybind11_protobuf (deleted at
# end of build). pybind11_protobuf's proto_api.h includes <Python.h>, so also
# put the host python headers on the same -I$PREFIX/include/python path.
mkdir -p $PREFIX/include/python
cp -r $PREFIX/include/google $PREFIX/include/python/
for _pyinc in $PREFIX/include/python3.*; do
  [ -d "$_pyinc" ] && cp -rn "$_pyinc"/. $PREFIX/include/python/ 2>/dev/null || true
done

cp ${RECIPE_DIR}/pybind11_protobuf/*.patch ${SRC_DIR}/third_party/pybind11_protobuf/.

# hmaarrfk - 2026/05/19 - systemlib (shared) protobuf descriptor guard.
# Install the two force-included guard headers into $PREFIX/include (a
# toolchain -isystem dir, for bare-name -include); see
# tf_proto_descriptor_guard.h for why. Removed at end of build_common.sh.
cp ${RECIPE_DIR}/tf_proto_descriptor_guard.h $PREFIX/include/tf_proto_descriptor_guard.h
cp ${RECIPE_DIR}/tf_proto_descriptor_guard_impl.h $PREFIX/include/tf_proto_descriptor_guard_impl.h
# systemlib abseil flag guard (see tf_absl_flag_guard.h); installed for
# bare-name -include resolution, removed at end of build.
cp ${RECIPE_DIR}/tf_absl_flag_guard.h $PREFIX/include/tf_absl_flag_guard.h

sed -i.bak "s;@@PREFIX@@;$PREFIX;" third_party/pybind11_protobuf/0002-Add-Python-include-path.patch

# abseil-cpp 20260107 removed the absl::Nonnull/Nullable/NullabilityUnknown<T>
# aliases that TF still uses; re-add them to the installed header as no-ops.
if [[ ! -f "${SRC_DIR}/nullability_patched" ]]; then
  cat ${RECIPE_DIR}/nullability_deprecated.h >> ${BUILD_PREFIX}/include/absl/base/nullability.h
  cat ${RECIPE_DIR}/nullability_deprecated.h >> ${PREFIX}/include/absl/base/nullability.h
  touch "${SRC_DIR}/nullability_patched"
fi

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
# do not build with MKL support
export TF_NEED_MKL=0
export BAZEL_MKL_OPT=""

mkdir -p ./bazel_output_base
export BAZEL_OPTS=""
# Set this to something as otherwise, it would include CFLAGS which itself contains a host path and this then breaks bazel's include path validation.
export CC_OPT_FLAGS="-O2"

if [[ "${target_platform}" == "linux-64" && "${microarch_level}" == "4" &&  "${CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
  # we can't use the x86-64-v4 emulator from Intel with bazel. Instead build with
  # - v4 for TF libraries
  # - v3 for external libraries
  # - v3 for TF executables
  CFLAGS=$(echo "$CFLAGS" | sed 's/-march=x86-64-v4/-march=x86-64-v3/g')
  CXXFLAGS=$(echo "$CXXFLAGS" | sed 's/-march=x86-64-v4/-march=x86-64-v3/g')
  CPPFLAGS=$(echo "$CPPFLAGS" | sed 's/-march=x86-64-v4/-march=x86-64-v3/g')
  BAZEL_OPTS="${BAZEL_OPTS} --copt=-march=x86-64-v${microarch_level} --host_copt=-march=x86-64-v3"
fi

# Quick debug:
# cp -r ${RECIPE_DIR}/build.sh . && bazel clean && bash -x build.sh --logging=6 | tee log.txt
# Dependency graph:
# bazel query 'deps(//tensorflow/tools/lib_package:libtensorflow)' --output graph > graph.in
if [[ "${target_platform}" == osx-* ]]; then
  # Same root cause as the linux branch below: TF 2.21.0's cc_shared_library
  # does not forward the systemlib linkopts, so the TF dylibs lack
  # LC_LOAD_DYLIB entries for the systemized libs and `import tensorflow`
  # fails at dlopen. ld64 rejects --no-as-needed/--export-dynamic, but listing
  # -l<name> adds the entry; abseil ships ~90 dylibs, so enumerate them.
  _absl_libs=""
  for _f in "${PREFIX}"/lib/libabsl_*.dylib; do
    [ -e "$_f" ] && _absl_libs="${_absl_libs} -l$(basename "$_f" .dylib | sed 's/^lib//')"
  done
  export LDFLAGS="${LDFLAGS} -framework CoreFoundation -Xlinker -undefined -Xlinker dynamic_lookup -lprotobuf -lgrpc -lgrpc++ -lgpr -lsqlite3 -lpng -ljpeg -lgif -lflatbuffers -licui18n -licuuc -licudata -lsnappy -lcurl -lz -lssl -lcrypto${_absl_libs}"
else
  # TF 2.21.0's cc_shared_library does not forward the systemlib linkopts, so
  # the libtensorflow*.so lack DT_NEEDED for the systemized third-party libs:
  # host tools crash dlopen-ing libtensorflow_framework.so and
  # libtensorflow_cc.so fails to link. Force-link every systemized library;
  # abseil ships ~90 shared objects, so enumerate them.
  _absl_libs=""
  for _f in "${PREFIX}"/lib/libabsl_*.so; do
    [ -e "$_f" ] && _absl_libs="${_absl_libs} -l$(basename "$_f" .so | sed 's/^lib//')"
  done
  export LDFLAGS="${LDFLAGS} -lrt -Wl,--export-dynamic -Wl,--no-as-needed -lprotobuf -lgrpc -lgrpc++ -lgpr -lsqlite3 -lpng -ljpeg -lgif -lflatbuffers -licui18n -licuuc -licudata -lsnappy -lcurl -lz -lssl -lcrypto${_absl_libs}"
fi

if [[ ${cuda_compiler_version} != "None" ]]; then
    if [ ${target_platform} == "linux-aarch64" ]; then
	NVARCH=sbsa
    elif [ ${target_platform} == "linux-64" ]; then
	NVARCH=x86_64
    else
	NVARCH=${ARCH}
    fi
    # NB: do NOT force-link libnvidia-ml or libcusparse into LDFLAGS here.
    # Under --config=cuda_wheel XLA's lazy-dlopen stubs leave the .so's with
    # no DT_NEEDED for them (CUDA libs are dlopen'd at first GPU use). Adding
    # -lnvidia-ml to LDFLAGS leaks through the per-token --linkopt= loop below
    # and -- because Bazel reorders linkopts and drops the --as-needed scope --
    # makes every output unconditionally NEED libnvidia-ml.so.1, which ships
    # only with the driver (no conda-forge package), breaking `import
    # tensorflow`.
    # clang compiles BOTH host and device CUDA code (TF_CUDA_CLANG=1,
    # --config=cuda_clang below). The previous nvcc-device/clang-host split
    # (TF_NVCC_CLANG) broke at clang 22: nvcc's EDG host frontend cannot parse
    # clang-22-era headers (absl nullability-on-classes and
    # __builtin_is_cpp_trivially_relocatable, protobuf __is_bitwise_cloneable,
    # clang 22's own xmmintrin.h __builtin_elementwise_sqrt), and unlike the
    # clang 18 this recipe used before, clang 22 fully supports CUDA 12.9/13.0
    # device compilation (max PTX 9.0), so single-compiler clang is now viable
    # -- and is upstream's primary supported CUDA build path.
    # configure.py on the TF_CUDA_CLANG=1 path reads CLANG_CUDA_COMPILER_PATH
    # (it only checks the path exists). GCC_HOST_COMPILER_PATH is unused on
    # this path; still exported to keep a revert to TF_NVCC_CLANG one-line.
    export TF_CUDA_CLANG=1
    export TF_NEED_CLANG=1
    # conda-forge's clang >= 19 compiler stack changed packaging:
    # clang_impl_linux-64 22 depends on the versioned `clang-22` package
    # (bin/clang-22 only); the unversioned bin/clang symlink lives in the
    # separate `clang` package, which is no longer pulled into the build env
    # (clang_impl_linux-64 18 depended on `clang` directly). Resolve whichever
    # raw clang driver actually exists.
    CLANG_BIN="${BUILD_PREFIX}/bin/clang"
    if [[ ! -x "${CLANG_BIN}" ]]; then
        CLANG_BIN="${BUILD_PREFIX}/bin/clang-${c_compiler_version%%.*}"
    fi
    if [[ ! -x "${CLANG_BIN}" ]]; then
        echo "ERROR: no clang driver found in ${BUILD_PREFIX}/bin (tried clang, clang-${c_compiler_version%%.*})" >&2
        exit 1
    fi
    export CLANG_CUDA_COMPILER_PATH="${CLANG_BIN}"
    export CLANG_COMPILER_PATH="${CLANG_BIN}"
    export GCC_HOST_COMPILER_PATH="${CLANG_BIN}"
    # nvcc / cicc / ptxas live under nvvm/bin in the conda cuda-nvcc package.
    export PATH="${PATH}:${BUILD_PREFIX}/nvvm/bin"

    # clang's CUDA-device frontend mis-parses absl btree.h's `friend iterator;`
    # on a type alias (llvm/llvm-project#29934). Rewrite the alias-based friends
    # into an equivalent template friend of btree_iterator in the conda header.
    _btree_h="${PREFIX}/include/absl/container/internal/btree.h"
    if [ -f "${_btree_h}" ]; then
      sed -i \
        -e 's/^  friend iterator;/  template <typename N1, typename R1, typename P1> friend class btree_iterator;/' \
        -e '/^  friend const_iterator;/d' \
        "${_btree_h}"
    fi

    export TF_NEED_CUDA=1
    export TF_CUDA_VERSION="${cuda_compiler_version}"
    export TF_CUDNN_VERSION="${cudnn}"
    export HERMETIC_CUDA_VERSION="${cuda_compiler_version}"
    export HERMETIC_CUDNN_VERSION="${cudnn}"
    export TF_NCCL_VERSION=$(pkg-config nccl --modversion | grep -Po '\d+\.\d+')

    export LDFLAGS="${LDFLAGS//-Wl,-z,now/-Wl,-z,lazy}"

    if [[ "${cuda_compiler_version}" == 12* || "${cuda_compiler_version}" == 13* ]]; then
        # As of clang 18 the host compiler only understood compute
        # capabilities up to sm_90; the Blackwell archs sm_100/sm_120 would
        # make clang error ("unsupported CUDA gpu architecture"). Cap the list
        # at sm_90 for now. The compiler pin has since moved to clang 22
        # (conda_build_config.yaml) to match TF 2.21.0's actual LLVM version --
        # worth re-checking whether sm_100/sm_120 can now be added, but that is
        # unverified so the cap is left in place here.
        if [[ "${cuda_compiler_version}" == 13* ]]; then
            # CUDA 13 dropped support for compute capabilities below sm_75
            export HERMETIC_CUDA_COMPUTE_CAPABILITIES=sm_75,sm_80,sm_86,sm_89,sm_90,compute_90
        else
            export HERMETIC_CUDA_COMPUTE_CAPABILITIES=sm_60,sm_70,sm_75,sm_80,sm_86,sm_89,sm_90,compute_90
        fi
        export CUDNN_INSTALL_PATH=$PREFIX
        export NCCL_INSTALL_PATH=$PREFIX
        export CUDA_HOME="${BUILD_PREFIX}/targets/${NVARCH}-linux"
        export TF_CUDA_PATHS="${BUILD_PREFIX}/targets/${NVARCH}-linux,${PREFIX}/targets/${NVARCH}-linux"
        # CUDA 13's cuda-cccl ships CUB/Thrust/libcudacxx under
        # include/cccl/, but gpu_prim.h and @cuda_cccl//:headers expect the
        # flat include/ layout; promote the cccl/ contents up before merging.
        for _t in "${PREFIX}" "${BUILD_PREFIX}"; do
            _cccl="${_t}/targets/${NVARCH}-linux/include/cccl"
            if [ -d "${_cccl}" ]; then
                cp -rn "${_cccl}"/. "${_t}/targets/${NVARCH}-linux/include/" 2>/dev/null || true
            fi
        done
        # XLA can only cope with a single cuda header include directory, merge both
        rsync -a ${PREFIX}/targets/${NVARCH}-linux/include/ ${BUILD_PREFIX}/targets/${NVARCH}-linux/include/

        # Although XLA supports a non-hermetic build, it still tries to find headers in the hermetic locations.
        # We do this in the BUILD_PREFIX to not have any impact on the resulting jaxlib package.
        # Otherwise, these copied files would be included in the package.
        rm -rf ${BUILD_PREFIX}/targets/${NVARCH}-linux/include/third_party
        mkdir -p ${BUILD_PREFIX}/targets/${NVARCH}-linux/include/third_party/gpus/cuda/extras/CUPTI
        cp -r ${PREFIX}/targets/${NVARCH}-linux/include ${BUILD_PREFIX}/targets/${NVARCH}-linux/include/third_party/gpus/cuda/
        cp -r ${PREFIX}/targets/${NVARCH}-linux/include ${BUILD_PREFIX}/targets/${NVARCH}-linux/include/third_party/gpus/cuda/extras/CUPTI/
        mkdir -p ${BUILD_PREFIX}/targets/${NVARCH}-linux/include/third_party/gpus/cudnn
        cp ${PREFIX}/include/cudnn*.h ${BUILD_PREFIX}/targets/${NVARCH}-linux/include/third_party/gpus/cudnn/
        mkdir -p ${BUILD_PREFIX}/targets/${NVARCH}-linux/include/third_party/nccl
        cp ${PREFIX}/include/nccl.h ${BUILD_PREFIX}/targets/${NVARCH}-linux/include/third_party/nccl/
        rsync -a ${PREFIX}/targets/${NVARCH}-linux/lib/ ${BUILD_PREFIX}/targets/${NVARCH}-linux/lib/
        mkdir -p ${BUILD_PREFIX}/targets/${NVARCH}-linux/bin
        ln -sf ${BUILD_PREFIX}/bin/fatbinary ${BUILD_PREFIX}/targets/${NVARCH}-linux/bin/fatbinary
        ln -sf ${BUILD_PREFIX}/bin/nvlink ${BUILD_PREFIX}/targets/${NVARCH}-linux/bin/nvlink
        ln -sf ${BUILD_PREFIX}/bin/ptxas ${BUILD_PREFIX}/targets/${NVARCH}-linux/bin/ptxas

        export LOCAL_CUDA_PATH="${BUILD_PREFIX}/targets/${NVARCH}-linux"
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

    else
        echo "unsupported cuda version."
        exit 1
    fi
else
    export TF_NEED_CUDA=0
fi

gen-bazel-toolchain

if [[ "${target_platform}" == "osx-64" ]]; then
  # Must match the cpu key gen-bazel-toolchain bakes into the
  # cc_toolchain_suite (darwin_x86_64); a bare "darwin" fails suite lookup.
  TARGET_CPU=darwin_x86_64
  # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
  export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
elif [[ "${target_platform}" == "linux-aarch64" ]]; then
  TARGET_CPU=aarch64
elif [[ "${target_platform}" == "linux-x86_64" ]]; then
  TARGET_CPU=x86_64
fi

# --cpu key for the cc_toolchain_suite lookup. The conda suite is keyed by
# ${TARGET_CPU}; TF's CUDA crosstool is keyed k8/aarch64, so CUDA needs k8.
CC_CPU=${TARGET_CPU}
if [[ "${cuda_compiler_version}" != "None" && "${target_platform}" == "linux-64" ]]; then
  CC_CPU=k8
fi

# build_common.sh runs many times and .bazelrc persists across runs, so
# restore it to the pristine upstream state before appending below. Otherwise
# the appended flags accumulate, changing every compile command and defeating
# Bazel's action caching (a full recompile every invocation).
if [[ ! -f .bazelrc.conda-orig ]]; then
  cp .bazelrc .bazelrc.conda-orig
else
  cp .bazelrc.conda-orig .bazelrc
fi

# Get rid of unwanted defaults
sed -i -e "/PROTOBUF_INCLUDE_PATH/c\ " .bazelrc
sed -i -e "/PREFIX/c\ " .bazelrc
# TF 2.21.0's pywrap build (USE_PYWRAP_RULES, kept enabled) keeps each protobuf
# descriptor in a single .so; the standalone libtensorflow(_cc) C/C++ libraries
# come from a separate non-pywrap pass below.
# TF's .bazelrc hardcodes -fuse-ld=lld but conda's clang ships no lld; drop it.
sed -i -e "/fuse-ld=lld/d" .bazelrc
# Ensure .bazelrc ends in a newline
echo "" >> .bazelrc

if [[ "${target_platform}" == osx-* ]]; then
  # TF 2.21.0's apple-toolchain config forces Bazel's Apple Xcode crosstool,
  # bypassing the conda //bazel_toolchain and its -isystem $PREFIX/include so
  # proto compiles fail to find conda headers; redirect it at the conda toolchain.
  sed -i 's#@local_config_apple_cc//:toolchain#//bazel_toolchain:toolchain#g' .bazelrc
  # cc_shared_library drops the systemlib -lprotobuf, and -undefined
  # dynamic_lookup cannot reconcile ThreadSafeArena::thread_cache_'s TLS storage
  # class; force-link conda's libprotobuf (target + host) so it resolves.
  cat >> .bazelrc <<EOF
build --linkopt=-L${PREFIX}/lib --linkopt=-lprotobuf
build --host_linkopt=-L${PREFIX}/lib --host_linkopt=-lprotobuf
EOF
fi

if [[ "${target_platform}" == "osx-arm64" ]]; then
  echo "build --config=macos_arm64" >> .bazelrc
  # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
  export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi
export TF_ENABLE_XLA=1
# Pass 1 builds the python wheel with the pywrap build (USE_PYWRAP_RULES on).
# The standalone libtensorflow / libtensorflow_cc C/C++ libraries are not
# declared as targets in the pywrap build, so they are built by a separate
# non-pywrap Bazel pass further down (LIBTF_TARGET).
export BUILD_TARGET="//tensorflow/tools/pip_package:wheel"
export LIBTF_TARGET="//tensorflow/tools/lib_package:libtensorflow //tensorflow:libtensorflow_cc${SHLIB_EXT}"

# Python settings
export PYTHON_BIN_PATH=${PYTHON}
export PYTHON_LIB_PATH=${SP_DIR}
export USE_DEFAULT_PYTHON_LIB_PATH=1

# additional settings
export TF_NEED_OPENCL=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_COMPUTECPP=0
# CUDA variants set TF_CUDA_CLANG=1 above; only force 0 for the non-CUDA build.
if [[ "${cuda_compiler_version}" == "None" ]]; then
  export TF_CUDA_CLANG=0
fi
if [[ "${target_platform}" == linux-* && "${cuda_compiler_version}" == "None" ]]; then
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

# Remove legacy flags set by configure that conflicts with CUDA 12+'s multi-directory approach.
if [[ "${cuda_compiler_version}" == 12* || "${cuda_compiler_version}" == 13* ]]; then
    sed -i '/CUDA_TOOLKIT_PATH/d' .tf_configure.bazelrc
fi

if [[ "${build_platform}" == linux-* ]]; then
  $RECIPE_DIR/add_py_toolchain.sh
fi

cat >> .bazelrc <<EOF
# Disable TF 2.21.0's hermetic LLVM CC toolchain so the conda-forge compiler
# and system headers are used (--crosstool_top is set per-variant below).
build --config=clang_local
build --logging=6
build --verbose_failures
# Upstream builds with -c opt (stock .bazelrc line ~93), whose STANDARD
# toolchains define NDEBUG -- but that injection is a toolchain feature, and
# the conda crosstools used here (bazel-toolchain; TF's CUDA crosstool
# wrapper) do not reliably provide it, leaving debug asserts live in release
# binaries (pip wheels contain none of them). On macOS this is fatal at
# runtime: tsl::down_cast's !NDEBUG dynamic_cast self-check aborts
# ("Assertion failed: f == nullptr || dynamic_cast<To>(f) != nullptr,
# casts.h") because RTTI type_info is duplicated across the two-level-
# namespace dylib pair, so cross-image dynamic_cast returns null for valid
# objects; ELF coalesces the duplicates so linux merely pays the assert
# overhead. Define NDEBUG explicitly to match upstream release semantics.
build --copt=-DNDEBUG --host_copt=-DNDEBUG
build --define=PREFIX=${PREFIX}
build --define=PROTOBUF_INCLUDE_PATH=${PREFIX}/include
build --cpu=${CC_CPU}
build --local_cpu_resources=${CPU_COUNT}
# Persistent content-addressed action cache so the per-Python and per-variant
# passes reuse artifacts across the wiped output tree; a no-op on fresh CI.
build --disk_cache=/tmp/tf-bazel-disk-cache
# systemlib protobuf descriptor guard (see tf_proto_descriptor_guard.h):
# force-include the featherweight header into every C++ TU and the heavy impl
# header into .pb.cc TUs only. Applied to target and exec/host configs.
build --copt=-include --copt=tf_proto_descriptor_guard.h
build --host_copt=-include --host_copt=tf_proto_descriptor_guard.h
build --per_file_copt=.*\.pb\.cc\$@-include,tf_proto_descriptor_guard_impl.h
build --host_per_file_copt=.*\.pb\.cc\$@-include,tf_proto_descriptor_guard_impl.h
# systemlib abseil flag guard (see tf_absl_flag_guard.h): force-include it into
# just the ABSL_FLAG-defining TUs (enumerated from the 2.21.0 source) so the
# same flag in >1 TF .so does not abort; a no-op on files without ABSL_FLAG.
build --per_file_copt=.*(common_runtime/next_pluggable_device/flags|common_runtime/next_pluggable_device/next_pluggable_device|runtime_fallback/bef_executor_flags|tfrt/saved_model/saved_model_testutil|gpu/cl/testing/performance_profiling|cpu/benchmarks/multi_benchmark_config|coordination/coordination_service_agent|coordination/coordination_service|tsl/platform/threadpool|tsl/util/filewrapper)\.cc\$@-include,tf_absl_flag_guard.h
build --host_per_file_copt=.*(common_runtime/next_pluggable_device/flags|common_runtime/next_pluggable_device/next_pluggable_device|runtime_fallback/bef_executor_flags|tfrt/saved_model/saved_model_testutil|gpu/cl/testing/performance_profiling|cpu/benchmarks/multi_benchmark_config|coordination/coordination_service_agent|coordination/coordination_service|tsl/platform/threadpool|tsl/util/filewrapper)\.cc\$@-include,tf_absl_flag_guard.h
EOF

# Per-variant crosstool: the CPU build uses the conda crosstool directly; the
# CUDA build routes through TF's CUDA crosstool, which (with
# --config=cuda_clang's cuda_compiler=clang) drives conda clang for host and
# device files alike, resolving CUDA bits via the local_config_cuda repos.
if [[ "${cuda_compiler_version}" == "None" ]]; then
  cat >> .bazelrc <<EOF
build --crosstool_top=//bazel_toolchain:toolchain
EOF
else
  # TF's CUDA crosstool lacks the conda customizations, and Bazel rejects an
  # undeclared absolute -isystem path. Feed $PREFIX/include via CPATH instead:
  # cuda_configure.bzl picks it up into cxx_builtin_include_dirs (declared,
  # hence accepted) and clang also searches CPATH at compile time.
  export CPATH="${PREFIX}/include${CPATH:+:${CPATH}}"
  export CPLUS_INCLUDE_PATH="${PREFIX}/include${CPLUS_INCLUDE_PATH:+:${CPLUS_INCLUDE_PATH}}"
  cat >> .bazelrc <<EOF
build --crosstool_top=@local_config_cuda//crosstool:toolchain
build --host_crosstool_top=@local_config_cuda//crosstool:toolchain
build --action_env=CPATH=${PREFIX}/include
build --host_action_env=CPATH=${PREFIX}/include
build --action_env=CPLUS_INCLUDE_PATH=${PREFIX}/include
build --host_action_env=CPLUS_INCLUDE_PATH=${PREFIX}/include
build --linkopt=-L${PREFIX}/lib --host_linkopt=-L${PREFIX}/lib
# TF's CUDA crosstool passes --cuda-path to plain C compiles too; tell clang
# to ignore unused command-line arguments (else -Werror trips).
build --copt=-Qunused-arguments
build --host_copt=-Qunused-arguments
EOF
  # Re-supply the force-linked systemlibs (linkopts are not path-validated).
  for _ldflag in ${LDFLAGS}; do
    echo "build --linkopt=${_ldflag}" >> .bazelrc
    echo "build --host_linkopt=${_ldflag}" >> .bazelrc
  done
fi

# conda's linux libabseil/libprotobuf use the pre-clang-18 Itanium mangling;
# clang 18 changed it, so pin clang to the GCC-compatible ABI to match the
# exported symbols. Only when building with clang (Apple clang / gcc reject it).
if [[ "${target_platform}" == linux-* && "${c_compiler}" == clang* ]]; then
  cat >> .bazelrc <<EOF
build --cxxopt=-fclang-abi-compat=17
build --host_cxxopt=-fclang-abi-compat=17
EOF
fi

# cuda_clang: clang builds both host and device code (see TF_CUDA_CLANG
# comment above). Requires lld (recipe.yaml adds it for CUDA variants) since
# the config links with -fuse-ld=lld.
if [[ "${cuda_compiler_version}" != "None" ]]; then
  cat >> .bazelrc <<EOF
build --config=cuda_clang
# --config=cuda_clang hardcodes --repo_env=HERMETIC_CUDA_COMPUTE_CAPABILITIES
# ="sm_60,sm_70,sm_80,sm_89,compute_90": no sm_75/sm_86, and sm_60/sm_70 are
# unsupported by CUDA 13. Re-assert the variant's list; these recipe lines
# append after .bazelrc's try-imports, so this later repo_env wins over the
# config expansion.
build --repo_env=HERMETIC_CUDA_COMPUTE_CAPABILITIES=${HERMETIC_CUDA_COMPUTE_CAPABILITIES}
# cuda_wheel sets include_cuda_libs=false so CUDA libs are dlopen'd lazily
# rather than hard-NEEDED; without it libtensorflow_framework.so.2 would need
# libcuda.so.1 at import time, which the conda test envs don't ship.
build --config=cuda_wheel
EOF
fi

# Update TF lite schema with latest flatbuffers version
pushd tensorflow/compiler/mlir/lite/schema
flatc --cpp --gen-object-api schema.fbs
popd
rm -f tensorflow/lite/schema/conversion_metadata_generated.h
rm -f tensorflow/lite/experimental/acceleration/configuration/configuration_generated.h
rm -f tensorflow/lite/acceleration/configuration/configuration_generated.h
sed -ie "s;BUILD_PREFIX;${BUILD_PREFIX};g" tensorflow/tools/pip_package/build_pip_package.py

# build using bazel
bazel build ${BUILD_TARGET} ${BAZEL_OPTS}

# copy the whl file. Bazel marks its outputs read-only, so a plain cp of an
# already-copied wheel fails; -f removes the stale destination and retries.
mkdir -p $SRC_DIR/tensorflow_pkg
cp -f bazel-bin/tensorflow/tools/pip_package/wheel_house/tensorflow*-cp${PY_VER/./}-*.whl $SRC_DIR/tensorflow_pkg/ || true

if [[ ! -f "${SRC_DIR}/libtensorflow_built" ]]; then
  # Pass 2: build the standalone libtensorflow / libtensorflow_cc C/C++
  # libraries with the NON-pywrap build (the pywrap build does not declare
  # these targets). USE_PYWRAP_RULES is stripped from .bazelrc just for this
  # pass; it is regenerated (pywrap on) on the next build_common.sh run.
  # Python-independent, so this runs once (guarded by the libtensorflow_built
  # marker created at the end of build.sh).
  sed -i -e "/USE_PYWRAP_RULES/d" .bazelrc
  bazel ${BAZEL_OPTS} build ${LIBTF_TARGET}

  # Build libtensorflow(_cc)
  mkdir -p ${PREFIX}/lib
  mkdir -p ${PREFIX}/include
  tar -C ${PREFIX} -xzf $SRC_DIR/bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz
  ls -alh ${PREFIX}/lib
  ls -alh ${PREFIX}/include
  cp -RP bazel-bin/tensorflow/libtensorflow_cc.* ${PREFIX}/lib/
  if [[ "${target_platform}" == osx-* ]]; then
    ln -sf ${PREFIX}/lib/libtensorflow_framework.2.dylib ${PREFIX}/lib/libtensorflow_framework.dylib
  fi
  # Make writable so patchelf can do its magic
  chmod u+w ${PREFIX}/lib/libtensorflow*

  mkdir -p ${PREFIX}/include/tensorflow
  rsync -r --chmod=D777,F666 --exclude '_solib*' --exclude '_virtual_includes/' --exclude 'pip_package/' --exclude 'lib_package/' --include '*/' --include '*.h' --include '*.inc' --exclude '*' bazel-bin/ ${PREFIX}/include
  rsync -r --chmod=D777,F666 --include '*/' --include '*.h' --include '*.inc' --exclude '*' tensorflow/cc ${PREFIX}/include/tensorflow/
  rsync -r --chmod=D777,F666 --include '*/' --include '*.h' --include '*.inc' --exclude '*' tensorflow/core ${PREFIX}/include/tensorflow/
  rsync -r --chmod=D777,F666 --include '*/' --include '*.h' --include '*.inc' --exclude '*' third_party/xla/third_party/tsl/ ${PREFIX}/include/
  rsync -r --chmod=D777,F666 --include '*/' --include '*' --exclude '*.cc' third_party/ ${PREFIX}/include/tensorflow/third_party/
  rsync -r --chmod=D777,F666 --include '*/' --include '*' --exclude '*.txt' bazel-work/external/eigen_archive/Eigen/ ${PREFIX}/include/tensorflow/third_party/Eigen/
  rsync -r --chmod=D777,F666 --include '*/' --include '*' --exclude '*.txt' bazel-work/external/eigen_archive/unsupported/ ${PREFIX}/include/tensorflow/third_party/unsupported/
  # Flatten XLA headers from nested external path to top-level include/xla/.
  # TF 2.21.0 renamed the XLA bazel repo @local_xla -> @xla.
  rsync -av "${PREFIX}/include/external/xla/xla/" "${PREFIX}/include/xla/"
  touch "${SRC_DIR}/libtensorflow_built"
fi

# This was only needed for protobuf_python
rm -rf $PREFIX/include/python
# The systemlib protobuf descriptor guard headers are build-only; never package them.
rm -f $PREFIX/include/tf_proto_descriptor_guard.h
rm -f $PREFIX/include/tf_proto_descriptor_guard_impl.h
rm -f $PREFIX/include/tf_absl_flag_guard.h
