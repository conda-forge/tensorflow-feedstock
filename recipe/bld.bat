IF "%PY_VER%"=="3.6" (
	%PYTHON% -m pip install --no-deps https://pypi.org/packages/cp36/t/tensorflow/tensorflow-%PKG_VERSION%-cp36-cp36m-win_amd64.whl
)
IF "%PY_VER%"=="3.7" (
	%PYTHON% -m pip install --no-deps https://pypi.org/packages/cp37/t/tensorflow/tensorflow-%PKG_VERSION%-cp37-cp37m-win_amd64.whl
)
if errorlevel 1 exit 1

rem we dont want to clobber the tensorboard package
del %PREFIX%\Scripts\tensorboard*
if errorlevel 1 exit 1
