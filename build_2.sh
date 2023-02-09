
function build_expat () {
  if [[ ! -e "${SRC}/lib/pkgconfig/expat.pc" ]]; then
    echo '♻️ ' Start compiling EXPAT
    cd ${CMPLD}
    cd expat-2.2.10
    ./configure --prefix=${SRC} --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_libiconv () {
  if [[ ! -e "${SRC}/lib/libiconv.a" ]]; then
    echo '♻️ ' Start compiling LIBICONV
    cd ${CMPLD}
    cd libiconv-1.16
    ./configure --prefix=${SRC} --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_enca () {
  if [[ ! -d "${SRC}/libexec/enca" ]]; then
    echo '♻️ ' Start compiling ENCA
    cd ${CMPLD}
    cd enca-1.19
    ./configure --prefix=${SRC} --disable-dependency-tracking --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_freetype () {
  if [[ ! -e "${SRC}/lib/pkgconfig/freetype2.pc" ]]; then
    echo '♻️ ' Start compiling FREETYPE
    cd ${CMPLD}
    cd freetype-2.10.4
    ./configure --prefix=${SRC} --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_gettext () {
  if [[ ! -e "${SRC}/lib/pkgconfig/gettext.pc" ]]; then
    echo '♻️ ' Start compiling gettext
    cd ${CMPLD}
    cd gettext-0.21
    ./configure --prefix=${SRC} --disable-dependency-tracking --disable-silent-rules --disable-debug --disable-shared --enable-static \
                --with-included-gettext --with-included-glib --with-includedlibcroco --with-included-libunistring --with-emacs \
                --disable-java --disable-csharp --without-git --without-cvs --without-xz
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_harfbuzz () {
  if [[ ! -e "${SRC}/lib/pkgconfig/harfbuzz.pc" ]]; then
    echo '♻️ ' Start compiling harfbuzz
    cd ${CMPLD}
    cd harfbuzz-2.7.2
    ./configure --prefix=${SRC} --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_vidstab () {
  if [[ ! -e "${SRC}/lib/pkgconfig/vidstab.pc" ]]; then
    echo '♻️ ' Start compiling Vid-stab
    cd ${CMPLD}
    cd vid.stab-1.1.0
    patch -p1 < fix_cmake_quoting.patch
    cmake . -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DLIBTYPE=STATIC -DBUILD_SHARED_LIBS=OFF -DUSE_OMP=OFF -DENABLE_SHARED=off
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_snappy () {
  if [[ ! -e "${SRC}/lib/libsnappy.a" ]]; then
    echo '♻️ ' Start compiling Snappy
    cd ${CMPLD}
    cd snappy-1.1.8
    cmake . -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DLIBTYPE=STATIC -DENABLE_SHARED=off
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

WORKDIR="$(pwd)/workdir"

SRC="$WORKDIR/sw"
CMPLD="$WORKDIR/compile"
NUM_PARALLEL_BUILDS=$(sysctl -n hw.ncpu)
export PATH=${SRC}/bin:$PATH
export CC=clang && export PKG_CONFIG_PATH="${SRC}/lib/pkgconfig"
export MACOSX_DEPLOYMENT_TARGET=11.0

if [[ "$(uname -m)" == "arm64" ]]; then
  export ARCH=arm64
else
  export ARCH=x86_64
fi

export LDFLAGS=${LDFLAGS:-}
export CFLAGS=${CFLAGS:-}

total_start_time="$(date -u +%s)"
build_expat
build_libiconv
build_enca
build_freetype
if [[ "$ARCH" == "arm64" ]]; then
  build_gettext
fi
build_harfbuzz
build_vidstab
build_snappy
total_end_time="$(date -u +%s)"
total_elapsed="$(($total_end_time-$total_start_time))"
echo "Total $total_elapsed seconds elapsed for build"
