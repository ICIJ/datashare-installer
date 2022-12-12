export DIST=dist
export VERSION=${VERSION}
export APPNAME=Datashare ${VERSION}
export INSTALLER_NAME=datashare-${VERSION}.exe

all: $(DIST)/$(INSTALLER_NAME)

$(DIST):
		mkdir -p $(DIST)

$(DIST)/$(INSTALLER_NAME): $(DIST)
		../mac/build/gen_file datashare.bat $(DIST)/datashare.bat
		makensis datashare.nsi

PHONY: clean
clean:
		rm -rf ${DIST}
