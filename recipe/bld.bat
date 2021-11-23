@echo on

set "PATH=%CD%:%PATH%"
set LIBDIR=%LIBRARY_BIN%
set INCLUDEDIR=%LIBRARY_INC%

set "TF_SYSTEM_LIBS=llvm,swig"

:: do not build with MKL support
set TF_NEED_MKL=0
set BAZEL_MKL_OPT=

mkdir -p ./bazel_output_base
set BAZEL_OPTS=

:: the following arguments are useful for debugging
::    --logging=6
::    --subcommands
:: jobs can be used to limit parallel builds and reduce resource needs
::    --jobs=20
:: Set compiler and linker flags as bazel does not account for CFLAGS,
:: CXXFLAGS and LDFLAGS.
set BUILD_OPTS="--copt=-march=nocona ^
--copt=-mtune=haswell ^
--copt=-ftree-vectorize ^
--copt=-fPIC ^
--copt=-fstack-protector-strong ^
--copt=-O2 ^
--cxxopt=-fvisibility-inlines-hidden ^
--cxxopt=-fmessage-length=0 ^
--linkopt=-zrelro ^
--linkopt=-znow ^
--verbose_failures ^
%BAZEL_MKL_OPT% ^
--config=opt"
set TF_ENABLE_XLA=0
set BUILD_TARGET="//tensorflow/tools/pip_package:build_pip_package //tensorflow:libtensorflow.so //tensorflow:libtensorflow_cc.so"

:: Python settings
set PYTHON_BIN_PATH=%PYTHON%
set PYTHON_LIB_PATH=%SP_DIR%
set USE_DEFAULT_PYTHON_LIB_PATH=1

:: additional settings
set CC_OPT_FLAGS="-march=nocona -mtune=haswell"
set TF_NEED_OPENCL=0
set TF_NEED_OPENCL_SYCL=0
set TF_NEED_COMPUTECPP=0
set TF_CUDA_CLANG=0
set TF_NEED_TENSORRT=0
set TF_NEED_ROCM=0
set TF_NEED_MPI=0
set TF_DOWNLOAD_CLANG=0
set TF_SET_ANDROID_WORKSPACE=0
:: can be removed for TF>=2.7
set TF_IGNORE_MAX_BAZEL_VERSION=1
:: try to avoid hangs in configure.py by setting environment
:: variables whose value might get prompted if missing, see
:: https://github.com/tensorflow/tensorflow/blob/master/configure.py
:: (searching for 'get_from_env_or_user_or_default')
:: PYTHON_BIN_PATH / CC_OPT_FLAGS set above already
set "HOST_C_COMPILER=%CC%"
set "HOST_CXX_COMPILER=%CXX%"

:: CUDA-enabled setup
if "%cuda_compiler_version%"=="None" (
    set "TF_NEED_CUDA=0"
) else (
    set "TF_NEED_CUDA=1"
    set "TF_CUDA_VERSION=%cuda_compiler_version%"
    set "TF_CUDNN_VERSION=%cudnn%"
    :: TODO
    set "TF_NCCL_VERSION=0.0.1"
    set "CLANG_CUDA_COMPILER_PATH=some\path\I\want\to\debug"

    REM %MY_VAR:~0,2% selects first two characters
    if "%cuda_compiler_version:~0,2%"=="11" (
        if "%cuda_compiler_version:~0,4%"=="11.0" (
            REM cuda 11.0 deprecates arches 35, 50
            set "TF_CUDA_COMPUTE_CAPABILITIES=sm_60,sm_62,sm_70,sm_72,sm_75,sm_80,compute_80"
        ) else (
            set "TF_CUDA_COMPUTE_CAPABILITIES=sm_60,sm_62,sm_70,sm_72,sm_75,sm_80,sm_86,compute_86"
        )
    )

    REM WIN+CUDA workarounds (copied from faiss-feedstock)
    del %BUILD_PREFIX%\bin\nvcc.bat
    set "CudaToolkitDir=%CUDA_PATH%"
    set "CUDAToolkit_ROOT=%CUDA_PATH%"
)

:: configure step
.\configure
if %ERRORLEVEL% neq 0 exit 1

:: build using bazel
bazel %BAZEL_OPTS% build %BUILD_OPTS% %BUILD_TARGET%
if %ERRORLEVEL% neq 0 exit 1

:: build a whl file
mkdir -p %SRC_DIR%\\tensorflow_pkg
bazel-bin\\tensorflow\\tools\\pip_package\\build_pip_package %SRC_DIR%\\tensorflow_pkg
if %ERRORLEVEL% neq 0 exit 1
