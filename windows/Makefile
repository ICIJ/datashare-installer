export DIST=dist
export VERSION=0.31
export APPNAME=Datashare ${VERSION}

# cf http://bomutils.dyndns.org/tutorial.html
dist: 
		mkdir -p ${DIST}
		makensis installDatashare.nsi

PHONY: clean
clean:
		rm -rf ${DIST}
