# Datashare installers for mac and windows

Basically the scripts are :

* testing the OS version to choose between docker for OS supporting virtualization or docker toolbox (including virtualbox)
* installing the right version of docker
* installing datashare run script based on docker-compose
* providing an uninstaller

## Windows

It is based on [Nullsoft Scriptable Install System](http://nsis.sourceforge.net). 

Under linux you can run `makensis installDatashare.nsi` with the package [nsis](https://packages.ubuntu.com/search?keywords=nsis).

## MacOS 

Based on [this tutorial](http://bomutils.dyndns.org/tutorial.html) (cf the [Makefile](mac/Makefile))
