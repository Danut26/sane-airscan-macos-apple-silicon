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

## Tested

Tested the functionalities:
- WSD / WS-Scan
- device discovery / real scanning

of the scanner:
- Xerox WorkCentre 3025

on the Apple Silicon ARM64 Mac:
- MacBook Air M3 running macOS Tahoe 26

The test confirmed everything working perfectly fine. Other scanners supported by upstream sane-airscan may also work, but were not tested by this project.

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
