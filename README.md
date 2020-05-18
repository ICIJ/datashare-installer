# Datashare installers for mac, windows and linux

There are two ways for running datashare : 

* with [docker](https://www.docker.com/) usually more for server setups
* with [java](https://www.java.com) we call it "standalone" : it includes elasticsearch in the JVM and has a smaller footprint than the docker version

So you will find 6 assets in [release list](https://github.com/ICIJ/datashare-installer/releases):
* `datashare-dist_6.5.0_all.deb` : installer for ubuntu/debian without docker
* `datashare.sh` :  bash shell script to run datashare with `docker-compose`
* `Datashare.pkg` : installer for mac with docker 
* `DatashareStandalone.pkg` : installer for mac with java
* `installDatashare.exe` : installer for windows with docker
* `installDatashareStandalone.exe` : installer for windows with java

To compile installers, just type `make clean dist` under mac or windows.

The installers are compiled under linux (ubuntu 16.04 tested).

# What installers are doing?

## Docker

Basically installer with docker are : 
* testing the OS version to choose between docker for OS supporting virtualization or docker toolbox (including virtualbox)
* installing the right version of docker
* installing datashare run script based on docker-compose
* providing an uninstaller (for windows)

## Java

With java the installers are: 

* checking if the JVM is installed and if not install it
* checking if the computer has tesseract OCR library installed and install it
* installing a launcher script that uses java and sets the right runtime options for datashare.

# How they are built?
## Windows

It is based on [Nullsoft Scriptable Install System](http://nsis.sourceforge.net). 

You will need to install the package [nsis](https://packages.ubuntu.com/search?keywords=nsis) 

You will also need the [inetc plugin](http://nsis.sourceforge.net/Inetc_plug-in). Just copy the `Plugin/x86-ansi/INetC.dll` under `/usr/share/nsis/Plugins`  

## MacOS 

Based on [this tutorial](http://bomutils.dyndns.org/tutorial.html) (cf the [Makefile](mac/Makefile))

You have to install the `cpio` package, [bomutils](https://github.com/hogliux/bomutils) and the [xar tarball](https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/xar/xar-1.5.2.tar.gz).

## Linux

It is a simple shell script that just runs docker-compose. It is not installing docker engine and docker compose.
