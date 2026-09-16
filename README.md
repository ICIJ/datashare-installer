<p align="center">
<a href="https://datashare.icij.org/">
  <img src="https://datashare.icij.org/android-chrome-512x512.png" width="158px">
</a>
<br>
Installers for Datashare
</p>

<div align="center">

| | Status |
| --: | :-- |
| **CI checks** | [![CircleCI](https://img.shields.io/circleci/build/github/ICIJ/datashare-installer/main?style=shield)](https://app.circleci.com/pipelines/github/ICIJ/datashare-installer) |
| **Latest version** | [![Latest version](https://img.shields.io/github/v/tag/icij/datashare-installer?style=shield)](https://github.com/ICIJ/datashare-installer/releases/latest) |
| **Release date** | [![Release date](https://img.shields.io/github/release-date/icij/datashare-installer?style=shield)](https://github.com/ICIJ/datashare-installer/releases/latest) |
| **Snap Store** | [![datashare](https://snapcraft.io/datashare/badge.svg)](https://snapcraft.io/datashare) |
| **Open issues** | [![Open issues](https://img.shields.io/github/issues/icij/datashare?style=shield&color=success)](https://github.com/ICIJ/datashare/issues/) |

</div>

# Datashare installers

This repository builds the [Datashare](https://datashare.icij.org/) installers for macOS, Windows and Linux. Each [release](https://github.com/ICIJ/datashare-installer/releases) publishes:

* `datashare-X.Y.Z.pkg` — macOS installer
* `datashare-X.Y.Z.exe` — Windows installer
* the [datashare snap](https://snapcraft.io/datashare) for Linux, built from [snap/snapcraft.yaml](snap/snapcraft.yaml)

The Datashare version the installers target is stored in [VERSION.txt](VERSION.txt), the bundled Elasticsearch version in [ELASTICSEARCH_VERSION.txt](ELASTICSEARCH_VERSION.txt).

## Repository layout

| Path | Purpose |
| :-- | :-- |
| [mac/](mac/) | macOS `.pkg` installer (flat package built with bomutils and xar, signed and notarized with rcodesign) |
| [windows/](windows/) | Windows `.exe` installer ([NSIS](https://nsis.sourceforge.io/)) |
| [snap/](snap/) | Linux [snap](https://snapcraft.io/datashare) definition |
| [scripts/deploy.sh](scripts/deploy.sh) | Uploads built installers to a GitHub release (run by the [Datashare CI](https://github.com/ICIJ/datashare/blob/main/.circleci/config.yml)) |
| [scripts/stats.py](scripts/stats.py) | Exports per-release download counts to `ds_stats.csv` |

## Build

Run `make help` to list targets. `VERSION` defaults to the content of `VERSION.txt`:

```bash
make mac                    # mac/dist/datashare-$(VERSION).pkg
make windows                # windows/dist/datashare-$(VERSION).exe
make VERSION=21.14.0 all    # both, for a specific version
```

### macOS

Built as a flat package following [this tutorial](http://bomutils.dyndns.org/tutorial.html) (cf [mac/Makefile](mac/Makefile)). You need `cpio`, `imagemagick`, `icnsutils`, [bomutils](https://github.com/hogliux/bomutils), [xar](https://github.com/mackyle/xar) and [rcodesign](https://github.com/indygreg/apple-platform-rs) (apple-codesign crate). `make -C mac package` builds an unsigned `.pkg` with no credentials. `make mac` (or `make -C mac all`) also signs and notarizes, which requires Apple credentials in environment variables: see [mac/README.md](mac/README.md).

### Windows

Built with [NSIS](https://nsis.sourceforge.io/) (`nsis` package on Ubuntu/Debian) and three plugins, each copied to `/usr/share/nsis/Plugins/`:

* [INetC](https://nsis.sourceforge.io/Inetc_plug-in) (`x86-unicode/INetC.dll`)
* [EnVar](https://nsis.sourceforge.io/EnVar_plug-in) (`x86-unicode/EnVar.dll`)
* [Untgz](https://nsis.sourceforge.io/Untgz_plug-in) (`untgz.dll`)

See [.circleci/config.yml](.circleci/config.yml) for the exact setup.

### Linux

The snap is built by Snapcraft from [snap/snapcraft.yaml](snap/snapcraft.yaml). It picks its version from the latest git tag and bundles OpenJDK 21, Tesseract OCR and the Datashare release tarball.

## What the installers do

* **macOS**: ensures Xcode Command Line Tools and a package manager (Homebrew, or MacPorts on older systems) are installed, installs Tesseract OCR and OpenJDK 21 with it, downloads the Datashare jar and Elasticsearch, installs `Datashare.app` and a `datashare` CLI.
* **Windows**: downloads and installs the Temurin JRE 21, Tesseract OCR and Elasticsearch, downloads the Datashare jar and creates the launcher.
* **Linux (snap)**: self-contained, bundles the JRE and Tesseract so nothing else is installed on the host.
