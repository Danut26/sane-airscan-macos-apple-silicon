#!/bin/bash
# Build the three macOS distribution packages from a tested ARM64 backend.
set -euo pipefail
[ "$#" -eq 2 ] || { echo "Usage: $0 BACKEND OUTPUT_DIRECTORY" >&2; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"
BACKEND="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
/bin/mkdir -p "$2"
OUTPUT="$(cd "$2" && pwd)"
/usr/bin/lipo -verify_arch arm64 "$BACKEND"
/usr/bin/nm -gU "$BACKEND" | /usr/bin/grep ' _sane_airscan_init$' >/dev/null
for name in Driver-Install Driver-Uninstall NAPS2-Integration; do
    [ ! -e "$OUTPUT/SANE-AirScan-macOS-AppleSilicon-$name.pkg" ] || {
        echo "Output already exists; choose a new directory." >&2; exit 1;
    }
done
WORK=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/airscan-packages-XXXXXXXX")
trap '/bin/rm -rf "$WORK"' EXIT
/bin/mkdir -p "$WORK/root/usr/local/lib/sane-airscan" "$WORK/driver" "$WORK/naps2" "$WORK/uninstall"
/usr/bin/install -m 755 "$BACKEND" "$WORK/root/usr/local/lib/sane-airscan/libsane-airscan.so.1"
/bin/cat > "$WORK/driver/preinstall" <<'EOF'
#!/bin/bash
set -euo pipefail
[ "$(/usr/bin/uname -m)" = arm64 ] || { echo "This package requires Apple Silicon." >&2; exit 1; }
for lib in libavahi-common.3.dylib libavahi-client.3.dylib libdbus-1.3.dylib libxml2.16.dylib libgnutls.30.dylib libjpeg.8.dylib libpng16.16.dylib libtiff.6.dylib; do
    [ -e "/opt/local/lib/$lib" ] || { echo "Missing MacPorts dependency: $lib" >&2; exit 1; }
done
if [ -f /usr/local/lib/sane-airscan/libsane-airscan.so.1 ]; then
    mkdir -p /usr/local/var/backups/sane-airscan
    backup=$(mktemp -d /usr/local/var/backups/sane-airscan/driver-XXXXXXXX)
    cp -p /usr/local/lib/sane-airscan/libsane-airscan.so.1 "$backup/"
    echo "Previous driver backed up to $backup"
fi
EOF
/bin/cat > "$WORK/driver/postinstall" <<'EOF'
#!/bin/bash
set -euo pipefail
mkdir -p /usr/local/lib/sane /usr/local/etc/sane.d
ln -sf /usr/local/lib/sane-airscan/libsane-airscan.so.1 /usr/local/lib/sane/libsane-airscan.1.so
if [ ! -f /usr/local/etc/sane.d/airscan.conf ]; then
    printf '[options]\ndiscovery = enable\nws-discovery = full\n' > /usr/local/etc/sane.d/airscan.conf
fi
EOF
/bin/cp "$HERE/integrate-naps2.sh" "$WORK/naps2/postinstall"
/bin/cp "$HERE/uninstall-driver.sh" "$WORK/uninstall/postinstall"
/bin/chmod 755 "$WORK/driver/"* "$WORK/naps2/postinstall" "$WORK/uninstall/postinstall"
/usr/bin/pkgbuild --root "$WORK/root" --scripts "$WORK/driver" --ownership recommended --identifier com.sane-airscan.macos --version 1.0.0 --install-location / "$OUTPUT/SANE-AirScan-macOS-AppleSilicon-Driver-Install.pkg"
/usr/bin/pkgbuild --nopayload --scripts "$WORK/naps2" --identifier com.sane-airscan.naps2-integration --version 1.0.0 "$OUTPUT/SANE-AirScan-macOS-AppleSilicon-NAPS2-Integration.pkg"
/usr/bin/pkgbuild --nopayload --scripts "$WORK/uninstall" --identifier com.sane-airscan.uninstall --version 1.0.0 "$OUTPUT/SANE-AirScan-macOS-AppleSilicon-Driver-Uninstall.pkg"
(cd "$OUTPUT" && /usr/bin/shasum -a 256 ./*.pkg > SHA256SUMS.txt)
echo "Packages built in $OUTPUT. Not signed with Developer ID Installer."
