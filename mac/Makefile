VERSION = $(shell cat ../../datashare/pom.xml | grep '<version>[0-9.]\+' | sed 's/<version>\([0-9.]\+\)<\/version>/\1/g' | tr -d '[:space:]')
DIST=dist
APP_NAME=Datashare ${VERSION}

# cf http://bomutils.dyndns.org/tutorial.html
dist: 
		mkdir -p ${DIST}/flat/base.pkg ${DIST}/flat/Resources/en.lproj ${DIST}/root/Applications
		./build/appify ../../datashare/datashare-dist/src/main/datashare.sh "${APP_NAME}"
		mv "${APP_NAME}.app" ${DIST}/root/Applications/
		( find ${DIST}/root | cpio -o --format odc --owner 0:80 | gzip -c ) > ${DIST}/flat/base.pkg/Payload
		cp PackageInfo ${DIST}/flat/base.pkg/
		NB_FILES=$(find ${DIST}/root | wc -l)
		SIZE=$(du -b -s ${DIST}/root)
		( find scripts | cpio -o --format odc --owner 0:80 | gzip -c ) > ${DIST}/flat/base.pkg/Scripts
		mkbom -u 0 -g 80 ${DIST}/root ${DIST}/flat/base.pkg/Bom
		cp Distribution ${DIST}/flat
		xar --compression none -cf "${DIST}/${APP_NAME}.pkg" ${DIST}/flat/*
		chmod +x "${DIST}/${APP_NAME}.pkg"

PHONY: clean
clean:
		rm -rf ${DIST}
