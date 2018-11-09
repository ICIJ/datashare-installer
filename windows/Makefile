export DIST=dist
export VERSION=0.45
export APPNAME=Datashare ${VERSION}

$(DIST):
		mkdir -p $(DIST)

# cf http://bomutils.dyndns.org/tutorial.html
$(DIST)/installDatashare.exe: $(DIST)
		../mac/build/gen_file docker-compose.yml $(DIST)/docker-compose.yml
		makensis installDatashare.nsi

PHONY: clean
clean:
		rm -rf ${DIST}
