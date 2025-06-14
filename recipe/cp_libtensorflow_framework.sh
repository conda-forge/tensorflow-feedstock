# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/lib_package/README.md
mkdir -p ${PWD}/tarball
tar -C ${PWD}/tarball -xzf $SRC_DIR/libtensorflow.tar.gz
mkdir -p ${PREFIX}/lib
mv ${PWD}/tarball/lib/libtensorflow.so* ${PREFIX}/lib
mv ${PWD}/tarball/lib/libtensorflow.*.dylib ${PREFIX}/lib

# Make writable so patchelf can do its magic
chmod u+w $PREFIX/lib/libtensorflow*
