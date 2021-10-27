@echo on

pushd tensorflow-estimator

set "WHEEL_DIR=%cd%\\wheel_dir"
mkdir -p %WHEEL_DIR%
bazel build tensorflow_estimator\\tools\\pip_package:build_pip_package
if %ERRORLEVEL% neq 0 exit 1

bazel-bin\\tensorflow_estimator\\tools\\pip_package\\build_pip_package %WHEEL_DIR%
if %ERRORLEVEL% neq 0 exit 1

%PYTHON% -m pip install --no-deps %WHEEL_DIR%\\*.whl
if %ERRORLEVEL% neq 0 exit 1

bazel clean
popd
