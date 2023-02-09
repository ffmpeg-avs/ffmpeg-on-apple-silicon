#!/bin/bash
set -exuo pipefail

WORKDIR="$(pwd)/workdir"
mkdir -p ${WORKDIR}

SRC="$WORKDIR/sw"
CMPLD="$WORKDIR/compile"
NUM_PARALLEL_BUILDS=$(sysctl -n hw.ncpu)

if [[ -e "${CMPLD}" ]]; then
  rm -rf "${CMPLD}"
fi

mkdir -p ${SRC}
mkdir -p ${CMPLD}

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

function ensure_package () {
  if [[ "$ARCH" == "arm64" ]]; then
    if [[ ! -e "/opt/homebrew/opt/$1" ]]; then
      echo "Installing $1 using Homebrew"
      brew install "$1"

      export LDFLAGS="-L/opt/homebrew/opt/$1/lib ${LDFLAGS}"
      export CFLAGS="-I/opt/homebrew/opt/$1/include ${CFLAGS}"
      export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/homebrew/opt/$1/lib/pkgconfig"
    fi
  else
    if [[ ! -e "/usr/local/opt/$1" ]]; then
      echo "Installing $1 using Homebrew"
      brew install "$1"
      export LDFLAGS="-L/usr/local/opt/$1/lib ${LDFLAGS}"
      export CFLAGS="-I/usr/local/opt/$1/include ${CFLAGS}"
      export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/local/opt/$1/lib/pkgconfig"
    fi
  fi
}

ensure_package pkgconfig
ensure_package libtool
ensure_package glib

if ! command -v autoreconf &> /dev/null; then
  brew install autoconf
fi
if ! command -v automake &> /dev/null; then
  brew install automake
fi
if ! command -v cmake &> /dev/null; then
  brew install cmake
fi

echo "Cloning required git repositories"
git clone --depth 1 -b master https://code.videolan.org/videolan/x264.git $CMPLD/x264 &
git clone --depth 1 -b master https://github.com/FFmpeg/FFmpeg $CMPLD/ffmpeg &
git clone https://github.com/saindriches/uavs3d.git $CMPLD/uavs3d &
wait

# statically linking glibc is discouraged
# echo "Downloading: glib (2.66.2)"
# curl -Ls -o - https://download.gnome.org/sources/glib/2.66/glib-2.66.2.tar.xz | tar Jxf - -C $CMPLD/
# curl -o "$CMPLD/glib-2.66.2/hardcoded-patchs.diff" https://raw.githubusercontent.com/Homebrew/formula-patches/6164294a75541c278f3863b111791376caa3ad26/glib/hardcoded-paths.diff
echo "Downloading: fribidi (1.0.10)"
{(curl -Ls -o - https://github.com/fribidi/fribidi/releases/download/v1.0.10/fribidi-1.0.10.tar.xz | tar Jxf - -C $CMPLD/) &};
echo "Downloading: vid.stab (1.1.0)"
curl -Ls -o - https://github.com/georgmartius/vid.stab/archive/v1.1.0.tar.gz | tar zxf - -C $CMPLD/
curl -s -o "$CMPLD/vid.stab-1.1.0/fix_cmake_quoting.patch" https://raw.githubusercontent.com/Homebrew/formula-patches/5bf1a0e0cfe666ee410305cece9c9c755641bfdf/libvidstab/fix_cmake_quoting.patch
echo "Downloading: snappy (1.1.8)"
{(curl -Ls -o - https://github.com/google/snappy/archive/1.1.8.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: enca (1.19)"
{(curl -Ls -o - https://dl.cihar.com/enca/enca-1.19.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: libiconv (1.16)"
{(curl -Ls -o - https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: zlib (1.2.11)"
{(curl -Ls -o - https://zlib.net/fossils/zlib-1.2.11.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: expat (2.2.10)"
{(curl -Ls -o - https://github.com/libexpat/libexpat/releases/download/R_2_2_10/expat-2.2.10.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: freetype (2.10.4)"
{(curl -Ls -o - https://download.savannah.gnu.org/releases/freetype/freetype-2.10.4.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: gettext (0.21)"
{(curl -Ls -o - https://ftp.gnu.org/gnu/gettext/gettext-0.21.tar.xz | tar Jxf - -C $CMPLD/) &};
echo "Downloading: fontconfig (2.13.93)"
{(curl -Ls -o - https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.93.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: libass (0.15.0)"
{(curl -Ls -o - https://github.com/libass/libass/releases/download/0.15.0/libass-0.15.0.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: yasm (1.3.0)"
{(curl -Ls -o - http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: pkg-config (0.29.2)"
{(curl -Ls -o - https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: nasm (2.15.05)"
{(curl -Ls -o - https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: harfbuzz (2.7.2)"
{(curl -Ls -o - https://github.com/harfbuzz/harfbuzz/releases/download/2.7.2/harfbuzz-2.7.2.tar.xz | tar Jxf - -C $CMPLD/) &};

wait

function build_fribidi () {
  if [[ ! -e "${SRC}/lib/pkgconfig/fribidi.pc" ]]; then
    echo '♻️ ' Start compiling FRIBIDI
    cd ${CMPLD}
    cd fribidi-1.0.10
    ./configure --prefix=${SRC} --disable-debug --disable-dependency-tracking --disable-silent-rules --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_nasm () {
  if [[ ! -e "${SRC}/bin/nasm" ]]; then
    echo '♻️ ' Start compiling NASM
    #
    # compile NASM
    #
    cd ${CMPLD}
    cd nasm-2.15.05
    ./configure --prefix=${SRC}
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_libuavs3d () {
    echo '♻️ ' Start compiling uavs3d
    #
    # compile uavs3d
    #
    cd ${CMPLD}
    cd uavs3d

    mkdir build/linux
    cd build/linux

    cmake -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DCMAKE_BUILD_TYPE=Release \
        -DCOMPILE_10BIT=1 -DBUILD_SHARED_LIBS=NO ../..

    make -j ${NUM_PARALLEL_BUILDS}
    make install
}

function build_pkgconfig () {
  if [[ ! -e "${SRC}/bin/pkg-config" ]]; then
    echo '♻️ ' Start compiling pkg-config
    cd ${CMPLD}
    cd pkg-config-0.29.2
    export LDFLAGS="-framework Foundation -framework Cocoa"
    ./configure --prefix=${SRC} --with-pc-path=${SRC}/lib/pkgconfig --with-internal-glib --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
    unset LDFLAGS
  fi
}

function build_zlib () {
  if [[ ! -e "${SRC}/lib/pkgconfig/zlib.pc" ]]; then
    echo '♻️ ' Start compiling ZLIB
    cd ${CMPLD}
    cd zlib-1.2.11
    ./configure --prefix=${SRC}
    make -j ${NUM_PARALLEL_BUILDS}
    make install
    rm ${SRC}/lib/libz.so* || true
    rm ${SRC}/lib/libz.* || true
  fi
}


total_start_time="$(date -u +%s)"
build_fribidi
build_nasm
build_pkgconfig
build_zlib
build_libuavs3d
total_end_time="$(date -u +%s)"
total_elapsed="$(($total_end_time-$total_start_time))"
echo "Total $total_elapsed seconds elapsed for build"
