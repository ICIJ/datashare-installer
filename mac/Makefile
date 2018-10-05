export DIST=dist
export VERSION=$(shell cat ../../datashare/pom.xml | grep '<version>[0-9.]\+' | sed 's/<version>\([0-9.]\+\)<\/version>/\1/g' | tr -d '[:space:]')
export APPNAME=Datashare ${VERSION}
export BUNDLE_ID=org.icij.Datashare

# cf http://bomutils.dyndns.org/tutorial.html
dist: 
		mkdir -p ${DIST}/flat/base.pkg ${DIST}/flat/Resources/en.lproj ${DIST}/root/Applications
		./build/appify ../../datashare/datashare-dist/src/main/datashare.sh "${APPNAME}"
		mv "${APPNAME}.app" ${DIST}/root/Applications/
		( find ${DIST}/root | cpio -o --format odc --owner 0:80 | gzip -c ) > ${DIST}/flat/base.pkg/Payload
		./build/gen_file PackageInfo ${DIST}/flat/base.pkg/PackageInfo
		( find scripts | cpio -o --format odc --owner 0:80 | gzip -c ) > ${DIST}/flat/base.pkg/Scripts
		mkbom -u 0 -g 80 ${DIST}/root ${DIST}/flat/base.pkg/Bom
		./build/gen_file Distribution ${DIST}/flat/Distribution
		xar --compression none -cf "${DIST}/${APPNAME}.pkg" ${DIST}/flat/*
		chmod +x "${DIST}/${APPNAME}.pkg"

PHONY: clean
clean:
		rm -rf ${DIST}
