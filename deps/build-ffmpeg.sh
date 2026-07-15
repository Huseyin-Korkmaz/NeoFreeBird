#!/usr/bin/env bash
set -Eeuo pipefail

# Builds the ffmpeg stack in deps/ffmpeg from source:
# OpenSSL + FFmpeg + the ffmpeg-kit-next Objective-C wrapper (libffmpegkit),
# compiled for iOS arm64 with the Xcode toolchain on macOS or cross-compiled
# with the Theos toolchain on Linux.
#
# FFMPEG_TAG must match what the deps/ffmpeg-kit-next submodule checkout
# expects (scripts/source.sh in the submodule).

MIN_IOS=14.0

OPENSSL_VERSION=3.5.7
FFMPEG_TAG=n8.1.2

DEPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_SRC="$DEPS_DIR/ffmpeg-kit-next/apple/src"
BUILD="${BUILD_DIR:-/tmp/nfb-ffmpeg-build}"

if [[ "$(uname)" == "Darwin" ]]; then
    JOBS="$(sysctl -n hw.ncpu)"
    SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
    CC_BIN="$(xcrun --sdk iphoneos -f clang)"
    CXX_BIN="$(xcrun --sdk iphoneos -f clang++)"
    AR_BIN="$(xcrun -f ar)"
    RANLIB_BIN="$(xcrun -f ranlib)"
    NM_BIN="$(xcrun -f nm)"
else
    JOBS="$(nproc)"
    THEOS="${THEOS:-/home/thea/theos}"
    TOOLCHAIN="$THEOS/toolchain/linux/iphone/bin"
    SDK="${SDK:-$(ls -d "$THEOS"/sdks/iPhoneOS*.sdk 2>/dev/null | sort -V | tail -1)}"
    CC_BIN="$TOOLCHAIN/clang"
    CXX_BIN="$TOOLCHAIN/clang++"
    AR_BIN="$TOOLCHAIN/ar"
    RANLIB_BIN="$TOOLCHAIN/ranlib"
    NM_BIN="$TOOLCHAIN/nm"
fi

[[ -d "$SDK" ]] || { echo "iPhoneOS SDK not found" >&2; exit 1; }
[[ -f "$KIT_SRC/FFmpegKit.m" ]] || { echo "ffmpeg-kit-next submodule missing; run: git submodule update --init deps/ffmpeg-kit-next" >&2; exit 1; }

mkdir -p "$BUILD/bin"

# Wrapper compilers so build systems that mangle multi-word CC still work.
cat > "$BUILD/bin/ios-clang" <<EOF
#!/usr/bin/env bash
exec "$CC_BIN" -target arm64-apple-ios$MIN_IOS -isysroot "$SDK" -miphoneos-version-min=$MIN_IOS "\$@"
EOF
cat > "$BUILD/bin/ios-clang++" <<EOF
#!/usr/bin/env bash
exec "$CXX_BIN" -target arm64-apple-ios$MIN_IOS -isysroot "$SDK" -miphoneos-version-min=$MIN_IOS "\$@"
EOF
chmod +x "$BUILD/bin/ios-clang" "$BUILD/bin/ios-clang++"

export PATH="$BUILD/bin:$PATH"

fetch() {
    local url="$1" out="$2"
    [[ -f "$out" ]] || curl -fL --retry 3 -o "$out" "$url"
}

# --- OpenSSL ---------------------------------------------------------------

OPENSSL_PREFIX="$BUILD/openssl-install"
if [[ ! -f "$OPENSSL_PREFIX/lib/libssl.a" ]]; then
    fetch "https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VERSION/openssl-$OPENSSL_VERSION.tar.gz" "$BUILD/openssl.tar.gz"
    rm -rf "$BUILD/openssl-$OPENSSL_VERSION"
    tar -xzf "$BUILD/openssl.tar.gz" -C "$BUILD"

    # ios64-cross expects an Xcode-style CROSS_TOP/SDKs/CROSS_SDK layout.
    mkdir -p "$BUILD/crosstop/SDKs"
    ln -sfn "$SDK" "$BUILD/crosstop/SDKs/iPhoneOS.sdk"

    pushd "$BUILD/openssl-$OPENSSL_VERSION" >/dev/null
    # The generated Makefile reads CROSS_* from the environment at build time too.
    export CROSS_TOP="$BUILD/crosstop" CROSS_SDK="iPhoneOS.sdk" CROSS_COMPILE=
    CC=ios-clang AR="$AR_BIN" RANLIB="$RANLIB_BIN" \
        ./Configure ios64-cross no-shared no-dso no-tests --prefix="$OPENSSL_PREFIX"
    make -j"$JOBS" build_libs
    make install_dev
    unset CROSS_TOP CROSS_SDK CROSS_COMPILE
    popd >/dev/null
    rm -rf "$BUILD/openssl-$OPENSSL_VERSION"
fi

# --- FFmpeg ----------------------------------------------------------------

FFMPEG_SRC="$BUILD/FFmpeg-$FFMPEG_TAG"
FFMPEG_PREFIX="$BUILD/ffmpeg-install"
if [[ ! -f "$FFMPEG_PREFIX/lib/libavcodec.a" ]]; then
    fetch "https://github.com/arthenica/FFmpeg/archive/refs/tags/$FFMPEG_TAG.tar.gz" "$BUILD/ffmpeg.tar.gz"
    rm -rf "$FFMPEG_SRC"
    tar -xzf "$BUILD/ffmpeg.tar.gz" -C "$BUILD"

    pushd "$FFMPEG_SRC" >/dev/null
    export PKG_CONFIG_PATH="$OPENSSL_PREFIX/lib/pkgconfig"
    # Mirrors the configuration of the previous prebuilt libraries
    # (ffmpeg-kit 6.0), minus bitcode, with min iOS raised to $MIN_IOS.
    ./configure \
        --prefix="$FFMPEG_PREFIX" \
        --enable-cross-compile --target-os=darwin --arch=aarch64 --cpu=armv8 \
        --cc=ios-clang --cxx=ios-clang++ --as=ios-clang \
        --ar="$AR_BIN" --ranlib="$RANLIB_BIN" --nm="$NM_BIN" \
        --extra-cflags="-DFFMPEG_KIT_ARM64 -DIOS -Wno-unused-function -Wno-deprecated-declarations -fstrict-aliasing" \
        --disable-shared --enable-static --enable-pthreads --enable-small \
        --enable-version3 --enable-openssl \
        --disable-programs --disable-doc --disable-debug \
        --disable-zlib --disable-bzlib --disable-iconv \
        --disable-videotoolbox --disable-audiotoolbox --disable-avfoundation \
        --disable-coreimage --disable-appkit --disable-opencl --disable-opengl \
        --disable-securetransport --disable-schannel --disable-sdl2 \
        --disable-xlib --disable-sndio --disable-alsa \
        --disable-v4l2-m2m --disable-indev=v4l2 --disable-indev=fbdev \
        --disable-outdev=v4l2 --disable-outdev=fbdev \
        --disable-vaapi --disable-vdpau --disable-cuda-llvm --disable-cuvid --disable-nvenc \
        --disable-neon-clobber-test --disable-xmm-clobber-test \
        --install-name-dir='@rpath'
    make -j"$JOBS"
    make install
    # Keep the tree for config.h (the kit build needs it), drop the objects.
    make clean
    popd >/dev/null
fi

# --- libffmpegkit ----------------------------------------------------------

KIT_BUILD="$BUILD/ffmpegkit-obj"
rm -rf "$KIT_BUILD"
mkdir -p "$KIT_BUILD"

KIT_CFLAGS=(
    -I"$KIT_SRC" -I"$FFMPEG_SRC" -I"$FFMPEG_PREFIX/include"
    -DFFMPEG_KIT_ARM64 -DIOS -DFFMPEG_KIT_BUILD_DATE="$(date +%Y%m%d)"
    -Oz -fstrict-aliasing
    -Wno-unused-function -Wno-deprecated-declarations
)

# Source list from apple/src/Makefile.am.
kit_sources=$(sed -n '/^libffmpegkit_la_SOURCES/,/^$/p' "$KIT_SRC/Makefile.am" | grep -oE '[A-Za-z0-9_/]+\.(m|c)')

for src in $kit_sources; do
    obj="$KIT_BUILD/$(echo "$src" | tr '/' '_').o"
    case "$src" in
        *.m) ios-clang -fobjc-arc "${KIT_CFLAGS[@]}" -c "$KIT_SRC/$src" -o "$obj" ;;
        *.c) ios-clang "${KIT_CFLAGS[@]}" -c "$KIT_SRC/$src" -o "$obj" ;;
    esac
done

"$AR_BIN" rcs "$KIT_BUILD/libffmpegkit.a" "$KIT_BUILD"/*.o
"$RANLIB_BIN" "$KIT_BUILD/libffmpegkit.a"

# --- Install into deps -----------------------------------------------------

rm -rf "$DEPS_DIR/ffmpeg"
mkdir -p "$DEPS_DIR/ffmpeg/lib/pkgconfig"
cp "$KIT_SRC"/*.h "$DEPS_DIR/ffmpeg/"
cp -r "$FFMPEG_PREFIX"/include/* "$DEPS_DIR/ffmpeg/"
cp "$FFMPEG_PREFIX"/lib/*.a "$OPENSSL_PREFIX"/lib/libssl.a "$OPENSSL_PREFIX"/lib/libcrypto.a "$KIT_BUILD/libffmpegkit.a" "$DEPS_DIR/ffmpeg/lib/"
cp "$FFMPEG_PREFIX"/lib/pkgconfig/*.pc "$OPENSSL_PREFIX"/lib/pkgconfig/*.pc "$DEPS_DIR/ffmpeg/lib/pkgconfig/"

echo "Done. Headers and libraries installed in $DEPS_DIR/ffmpeg."
