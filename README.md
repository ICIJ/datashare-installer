# Datashare installers for Mac, Windows and Linux

You will find several assets in [release list](https://github.com/ICIJ/datashare-installer/releases):

* `datashare-6.5.0.pkg` : installer for MacOS
* `datashare-6.5.0.exe` : installer for Windows
* `datashare-6.5.0.deb` : installer for Ubuntu/Debian
* `datashare-6.5.0.sh` :  bash shell script to run datashare with `Docker`/`docker-compose`

To compile installers, just run `make VERSION=10.15.0 clean all`.

# What installers do?

* **Mac only**: ensure either XCode Command Line Tools or XCode are installed
* **Mac only**: ensure either MacPorts or Homebrew are installed
* check if the JVM is installed and if not install it
* check if the computer has tesseract OCR library installed and install it
* installing a launcher script that uses -Jjava and sets the right runtime options for Datashare.

# How they are built?

## Windows

It is based on [Nullsoft Scriptable Install System](http://nsis.sourceforge.net). 

You will need to install the package [nsis](https://packages.ubuntu.com/search?keywords=nsis) 

You will also need the [inetc plugin](http://nsis.sourceforge.net/Inetc_plug-in). Just copy the `Plugin/x86-ansi/INetC.dll` under `/usr/share/nsis/Plugins/x86-ansi/`  

## MacOS 

Based on [this tutorial](http://bomutils.dyndns.org/tutorial.html) (cf the [Makefile](mac/Makefile))

You have to install the `cpio` package, [bomutils](https://github.com/hogliux/bomutils) and the [xar tarball](https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/xar/xar-1.5.2.tar.gz).

## Linux

It is a simple shell script that just runs docker-compose. It is not installing docker engine and docker compose.
