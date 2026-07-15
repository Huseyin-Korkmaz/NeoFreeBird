# Dependencies

## Vendored source

- **JGProgressHUD** — https://github.com/JonasGessner/JGProgressHUD (MIT). Upstream is dormant but stable; vendored so it compiles directly into the tweak.

## Submodules

- **libflex/FLEX** — https://github.com/FLEXTool/FLEX, wrapped as the `libbhFLEX` subproject.
- **zxPluginsInject** — https://github.com/asdfzxcvbn/zxPluginsInject (v1.0.1), only built for sideloaded packages.
- **ffmpeg-kit-next** — https://github.com/arthenica/ffmpeg-kit-next (v8.1.0), source of the
  libffmpegkit wrapper and the pin for the FFmpeg version below. Only needed when
  regenerating the prebuilt libraries.

## Built from source (`ffmpeg/`: headers at the top, libraries in `ffmpeg/lib/`)

ffmpeg-kit-next 8.1.0 (FFmpeg n8.1.2, OpenSSL 3.5.7), arm64 iOS, static only.
Not tracked in git: `build.sh` runs `deps/build-ffmpeg.sh` automatically when
the libraries are missing, compiling with Xcode on macOS or cross-compiling
with the Theos toolchain on Linux (~20 minutes cold, cached under /tmp
afterwards). The FFmpeg configuration mirrors the original BHTwitter
ffmpeg-kit 6.0 build (`--enable-small`, OpenSSL for TLS, all platform
integrations disabled).

## Machine prerequisites

- **Theos** at `$THEOS`.
- **Cephei / CepheiPrefs / CepheiUI** in `$THEOS/lib` (linked via `EXTRA_FRAMEWORKS`).
- **cyan** (pyzule-rw) for the IPA merge steps in `build.sh`.
