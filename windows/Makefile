export DIST=dist
export VERSION=${VERSION}
export APPNAME=Datashare-${VERSION}

$(DIST):
		mkdir -p $(DIST)

# cf http://bomutils.dyndns.org/tutorial.html
$(DIST)/installDatashare.exe: $(DIST)
		../mac/build/gen_file docker-compose.yml $(DIST)/docker-compose.yml
		makensis installDatashare.nsi

$(DIST)/installDatashareStandalone.exe: $(DIST)
		../mac/build/gen_file datashareStandalone.bat $(DIST)/datashareStandalone.bat
		makensis installDatashareStandalone.nsi

PHONY: clean
clean:
		rm -rf ${DIST}
