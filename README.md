# Datashare installers for mac and windows

Basically the scripts are :

* testing the OS version to choose between docker for OS supporting virtualization or docker toolbox (including virtualbox)
* installing the right version of docker
* installing datashare run script based on docker-compose
* providing an uninstaller

To compile installers, just type `make clean dist` under mac or windows.

The installers are compiled under linux (ubuntu 16.04 tested).

## Windows

It is based on [Nullsoft Scriptable Install System](http://nsis.sourceforge.net). 

You will need to install the package [nsis](https://packages.ubuntu.com/search?keywords=nsis) 
You will also need the [inetc plugin](http://nsis.sourceforge.net/Inetc_plug-in). You will need to copy the `Plugin/x86-ansi/INetC.dll` under `/usr/share/nsis/Plugins`  

## MacOS 

Based on [this tutorial](http://bomutils.dyndns.org/tutorial.html) (cf the [Makefile](mac/Makefile))

You have to install the `cpio` package and the [xar tarball](https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/xar/xar-1.5.2.tar.gz).
