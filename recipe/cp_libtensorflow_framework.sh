# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/lib_package/README.md
mkdir -p ${PWD}/tarball
tar -C ${PWD}/tarball -xzf $SRC_DIR/libtensorflow.tar.gz
mkdir -p ${PREFIX}/lib
if [[ "$target_platform" == "osx-"* ]]; then
  mv ${PWD}/tarball/lib/libtensorflow_framework.*dylib ${PREFIX}/lib
else
  mv ${PWD}/tarball/lib/libtensorflow_framework.so* ${PREFIX}/lib
fi

# Make writable so patchelf can do its magic
chmod u+w $PREFIX/lib/libtensorflow_framework*
