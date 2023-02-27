

function build_ffmpeg () {
  echo '♻️ ' Start compiling FFMPEG
  cd ${CMPLD}
  cd ffmpeg
  sed -i '2243c \        } else if (ist->dec_ctx->codec_id != AV_CODEC_ID_AVS3)' fftools/ffmpeg.c
  export LDFLAGS="-L${SRC}/lib ${LDFLAGS:-}"
  export CFLAGS="-I${SRC}/include ${CFLAGS:-}"
  export LDFLAGS="$LDFLAGS -lexpat -lenca -lfribidi -liconv -lstdc++ -lfreetype -framework CoreText -framework VideoToolbox"
  ./configure --prefix=${WORKDIR}/ffmpeg --extra-cflags="-fno-stack-check" --arch=${ARCH} --cc=/usr/bin/clang \
              --enable-gpl \
              --enable-libfreetype \
              --enable-libvidstab --enable-libsnappy --enable-version3 --pkg-config-flags="--static"  \
              --disable-ffplay --enable-postproc --enable-nonfree --enable-runtime-cpudetect --enable-libuavs3d
  echo "build start"
  start_time="$(date -u +%s)"
  make -j ${NUM_PARALLEL_BUILDS}
  end_time="$(date -u +%s)"
  elapsed="$(($end_time-$start_time))"
  make install
  echo "[FFmpeg] $elapsed seconds elapsed for build"
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
build_ffmpeg
total_end_time="$(date -u +%s)"
total_elapsed="$(($total_end_time-$total_start_time))"
echo "Total $total_elapsed seconds elapsed for build"
