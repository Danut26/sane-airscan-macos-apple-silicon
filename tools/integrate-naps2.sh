#!/bin/bash
# Update an existing integration, or create one from the official NAPS2 app.
set -euo pipefail
[ "$EUID" -eq 0 ] || { echo "Run this installer as administrator." >&2; exit 1; }
DRIVER=/usr/local/lib/sane-airscan/libsane-airscan.so.1
APP=/Applications/NAPS2-AppleSilicon.app
SOURCE="$APP"
[ -d "$SOURCE" ] || SOURCE=/Applications/NAPS2.app
[ -f "$DRIVER" ] || { echo "Install the AirScan driver first." >&2; exit 1; }
[ -d "$SOURCE" ] || { echo "Install NAPS2 in /Applications first." >&2; exit 1; }
if /usr/bin/pgrep -x NAPS2 >/dev/null; then
    echo "Close NAPS2 before installing; no processes were stopped." >&2
    exit 1
fi
/usr/bin/lipo -verify_arch arm64 "$DRIVER"
/usr/bin/nm -gU "$DRIVER" | /usr/bin/grep ' _sane_airscan_init$' >/dev/null
SANE=Contents/Resources/_macarm/sane
CONF=Contents/Resources/_config/sane
[ -d "$SOURCE/$SANE" ] && [ -f "$SOURCE/$CONF/dll.conf" ] || {
    echo "Unsupported NAPS2 layout: ARM64 SANE backend or configuration missing." >&2
    exit 1
}
STAGE=$(/usr/bin/mktemp -d /Applications/.sane-airscan-XXXXXXXX)
cleanup() { /bin/rm -rf "$STAGE"; }
trap cleanup EXIT
/usr/bin/ditto "$SOURCE" "$STAGE/NAPS2-AppleSilicon.app"
NEW="$STAGE/NAPS2-AppleSilicon.app"
/usr/bin/install -m 755 "$DRIVER" "$NEW/$SANE/libsane-airscan.1.so"
if ! /usr/bin/grep -qxF airscan "$NEW/$CONF/dll.conf"; then
    /usr/bin/printf '\nairscan\n' >> "$NEW/$CONF/dll.conf"
fi
if [ ! -f "$NEW/$CONF/airscan.conf" ]; then
    /bin/cat > "$NEW/$CONF/airscan.conf" <<'EOF'
[options]
discovery = enable
ws-discovery = full
EOF
fi
/usr/bin/codesign --force --deep --sign - "$NEW"
/usr/bin/codesign --verify --deep "$NEW"
/bin/rm -rf "$APP"
if ! /bin/mv "$NEW" "$APP"; then
    echo "Could not install the prepared NAPS2 app." >&2
    exit 1
fi
echo "NAPS2 integration installed: $APP"
echo "Existing scanner configuration and NAPS2 profiles were preserved."
