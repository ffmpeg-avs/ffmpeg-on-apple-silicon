# FFmpeg for ARM-based Apple Silicon Macs

I've successfully built FFmpeg on my M1 Mac Mini with the build script included in this repository which is based on [OSXExperts.NET Guide](https://www.osxexperts.net).

```bash
$ ./ffmpeg 
ffmpeg version git-2023-02-09-458ae40 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration: --prefix=/Users/dreamfly/Downloads/build-ffmpeg-test-main/workdir/ffmpeg --extra-cflags=-fno-stack-check --arch=arm64 --cc=/usr/bin/clang --enable-gpl --enable-libfreetype --enable-libvidstab --enable-libsnappy --enable-version3 --pkg-config-flags=--static --disable-ffplay --enable-postproc --enable-nonfree --enable-runtime-cpudetect --enable-libuavs3d
  libavutil      57. 44.100 / 57. 44.100
  libavcodec     59. 63.100 / 59. 63.100
  libavformat    59. 38.100 / 59. 38.100
  libavdevice    59.  8.101 / 59.  8.101
  libavfilter     8. 56.100 /  8. 56.100
  libswscale      6.  8.112 /  6.  8.112
  libswresample   4.  9.100 /  4.  9.100
  libpostproc    56.  7.100 / 56.  7.100
Hyper fast Audio and Video encoder
usage: ffmpeg [options] [[infile options] -i infile]... {[outfile options] outfile}...

$ lipo -archs ffmpeg
arm64
```

## Dynamically linked libraries

The following package(s) will be linked dynamically because it is discouraged linking statically:

- glib

## Guide

Before you start you must install arm64-based Homebrew to `/opt/homebrew`.

1. Clone this repository.
2. Run `./build_1.sh`.
3. Run `./build_2.sh`.
4. Run `./build_3.sh`.
