# sane-airscan scanner driver for macOS Apple Silicon

Native ARM64 scanner driver for modern macOS, based on sane-airscan.

Provides network scanning support using:
- WSD / WS-Scan
- eSCL / AirScan
- SANE-compatible scanning applications

# ❤️ Support this project

Help keep this project maintained and compatible with future macOS versions.

[Support the project on GitHub Sponsors](https://github.com/sponsors/Danut26)

Available options:
- $1 / month
- $5 one-time

## Purpose

Being an owner of the XEROX WorkCentre 3025 and the EPSON Expression Home XP-205 printer / scanner multifunctionals, I was unable anymore to use their scanning capabilities on my new MacBook Air M3, as XEROX and EPSON did not continue to release any drivers for these products in order to support the Apple Silicon computers. At this point I browsed the internet and searched for any third party driver for Apple Silicon computers without any result. Then I have asked myself if it is possible to recompile an existing driver for this processors type. And the only solution available was the sane-airscan generic driver. At the end, everything worked fine and I was able to use the scanner once again on a new macOS release. I have then decided to share the entire project with everybody through GitHub, in order for others to freely benefit, enjoy and use the recompiled driver. From my point of view, I would gladly appreciate if a very moderate amount will be donated in order to support the existence of this driver for future macOS releases.

## Tested

Tested scanners:
- Xerox WorkCentre 3025
- Epson Expression Home XP-205

Network discovery and real scanning over WSD / WS-Scan were successfully tested with NAPS2-AppleSilicon on a MacBook Air M3 (ARM64). This release retains the same tested scanning backend.

Related models expected to be compatible, but not individually tested:
- Epson Expression Home XP-200 / XP-207
- Xerox WorkCentre 3025BI / 3025NI

## Requirements

The scanner and the Mac must already be connected to the same Wi-Fi network.

Install MacPorts for Apple Silicon, then run:

    sudo port install avahi gnutls
    sudo port load dbus
    sudo port load avahi

The driver installer checks that Avahi, D-Bus and GnuTLS are available.

## Install driver

    sudo installer -pkg SANE-AirScan-macOS-AppleSilicon-Driver-Install.pkg -target /

Installed driver:

    /usr/local/lib/sane-airscan/libsane-airscan.so.1

Configuration:

    /usr/local/etc/sane.d/airscan.conf

## NAPS2 integration

Install NAPS2 normally in:

    /Applications/NAPS2.app

Then install:

    sudo installer -pkg SANE-AirScan-macOS-AppleSilicon-NAPS2-Integration.pkg -target /

The integration package creates:

    /Applications/NAPS2-AppleSilicon.app

The original NAPS2 application is not modified.

Open NAPS2-AppleSilicon and create a scanner profile using:

    SANE Driver -> Choose device

## Uninstall driver

    sudo installer -pkg SANE-AirScan-macOS-AppleSilicon-Driver-Uninstall.pkg -target /

## Package signing

The current PKG files are not signed with an Apple Developer ID Installer certificate.

Installation from Terminal using sudo installer is the tested method.

## Source

Based on sane-airscan by Alexander Pevzner:

https://github.com/alexpevzner/sane-airscan

This repository contains the macOS Apple Silicon changes used to build this release.

## License

GPL-2.0
