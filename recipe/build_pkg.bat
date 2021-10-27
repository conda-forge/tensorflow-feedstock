:: install the whl using pip
pip install --no-deps %SRC_DIR%\\tensorflow_pkg\\*.whl
if %ERRORLEVEL% neq 0 exit 1

:: The tensorboard package has the proper entrypoint
rm -f %LIBRARY_BIN%\\tensorboard
