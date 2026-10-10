#!/bin/bash
# Remove this driver's system files and integrated NAPS2 copy; keep a backup.
set -euo pipefail
[ "$EUID" -eq 0 ] || { echo "Run this uninstaller as administrator." >&2; exit 1; }
if /usr/bin/pgrep -x NAPS2 >/dev/null; then
    echo "Close NAPS2 before uninstalling; no processes were stopped." >&2
    exit 1
fi
/bin/mkdir -p /usr/local/var/backups/sane-airscan
BACKUP=$(/usr/bin/mktemp -d /usr/local/var/backups/sane-airscan/uninstall-XXXXXXXX)
DRIVER=/usr/local/lib/sane-airscan
CONF=/usr/local/etc/sane.d/airscan.conf
APP=/Applications/NAPS2-AppleSilicon.app
if [ -d "$DRIVER" ]; then /usr/bin/ditto "$DRIVER" "$BACKUP/sane-airscan"; fi
if [ -f "$CONF" ]; then /bin/cp -p "$CONF" "$BACKUP/airscan.conf"; fi
if [ -d "$APP" ]; then /usr/bin/ditto "$APP" "$BACKUP/NAPS2-AppleSilicon.app"; fi
# Only the project-owned integration is removed; NAPS2.app and user profiles remain.
/bin/rm -rf "$APP" "$DRIVER"
/bin/rm -f /usr/local/lib/sane/libsane-airscan.1.so "$CONF"
/usr/sbin/pkgutil --forget com.sane-airscan.macos >/dev/null 2>&1 || true
/usr/sbin/pkgutil --forget com.sane-airscan.naps2-integration >/dev/null 2>&1 || true
echo "SANE-AirScan driver and NAPS2 integration removed. Backup: $BACKUP"
