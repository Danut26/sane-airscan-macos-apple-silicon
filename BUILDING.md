# Building for macOS Apple Silicon

Use an ARM64 Mac, Xcode Command Line Tools, MacPorts development libraries for
Avahi, GnuTLS, libxml2, JPEG, PNG and TIFF, and the public SANE headers. The
Makefile discovers library flags through pkg-config. Build in a clean source
directory:

```sh
make CC=clang PKG_CONFIG=/opt/local/bin/pkg-config CPPFLAGS=-I/path/to/sane/include
make check CC=clang PKG_CONFIG=/opt/local/bin/pkg-config CPPFLAGS=-I/path/to/sane/include
bash tools/build-packages.sh ./libsane-airscan.so.1 /path/to/packages
```

The header directory must contain `sane/sane.h` and `sane/saneopts.h`. Public
headers from SANE 1.4.0 were used for this ARM64 build. Runtime dependencies
remain in `/opt/local`; they are not bundled in the packages. The package build
refuses to overwrite existing outputs and creates the three packages named in
README.md, with package version 1.0.0. Packages are unsigned; the integrated
NAPS2 app receives an ad-hoc signature after its bundled backend is installed.

NAPS2 uses its own bundled SANE environment. `tools/integrate-naps2.sh` places
the backend in `Contents/Resources/_macarm/sane/libsane-airscan.1.so`, enables
`airscan` in its bundled `dll.conf`, and creates a generic discovery
configuration only when one is absent. It updates NAPS2-AppleSilicon if present
or creates it from NAPS2.app, without changing the original app. Existing
configuration and user profiles are preserved. The installer validates the
ARM64 layout, stages and verifies the signed app, and backs up a previous
integration. Close NAPS2 before installation or removal.

The uninstall package backs up and removes the system backend, its alias and
configuration, and the integrated NAPS2-AppleSilicon app. It leaves the original
NAPS2.app, user profiles and MacPorts dependencies installed.

The backend discovers supported eSCL and WSD scanners without device-specific
addresses or location restrictions. Physical discovery, capability queries,
and NAPS2 SANE enumeration were verified with a Xerox WorkCentre 3025. The
automated suite covers URI parsing, ZeroConf fixtures and concurrent HTTP
requests with a stalled connection. These checks do not establish physical
scanning compatibility for every model or protocol.
