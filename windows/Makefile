export DIST=dist
export VERSION=${VERSION}
export APPNAME=Datashare-${VERSION}

$(DIST):
		mkdir -p $(DIST)

# cf http://bomutils.dyndns.org/tutorial.html
$(DIST)/installDatashare.exe: $(DIST)
		../mac/build/gen_file docker-compose.yml $(DIST)/docker-compose.yml
		makensis installDatashare.nsi

$(DIST)/installDatashareLight.exe: $(DIST)
		makensis installDatashareLight.nsi

PHONY: clean
clean:
		rm -rf ${DIST}
