export DIST=dist
export VERSION=0.31
export APPNAME=Datashare ${VERSION}

# cf http://bomutils.dyndns.org/tutorial.html
dist: 
		mkdir -p ${DIST}
		../mac/build/gen_file docker-compose.yml dist/docker-compose.yml
		makensis installDatashare.nsi

PHONY: clean
clean:
		rm -rf ${DIST}
