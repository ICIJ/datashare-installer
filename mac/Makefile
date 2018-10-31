export DIST=dist
export VERSION=0.36
export APPNAME=Datashare
export BUNDLE_ID=org.icij.Datashare

# cf http://bomutils.dyndns.org/tutorial.html
dist:
		mkdir -p ${DIST}/flat/base.pkg ${DIST}/flat/Resources/en.lproj ${DIST}/root/Applications
		./build/gen_file datashare.sh ${DIST}/datashare.sh
		./build/appify ${DIST}/datashare.sh "${APPNAME}"
		mv "${APPNAME}.app" ${DIST}/root/Applications/
		( cd ${DIST}/root && find . | cpio -o --format odc --owner 0:80 | gzip -c ) > ${DIST}/flat/base.pkg/Payload
		./build/gen_file PackageInfo ${DIST}/flat/base.pkg/PackageInfo
		( cd scripts && find * | cpio -o --format odc --owner 0:80 | gzip -c ) > ${DIST}/flat/base.pkg/Scripts
		( cd ${DIST} && mkbom -u 0 -g 80 root flat/base.pkg/Bom )
		./build/gen_file Distribution ${DIST}/flat/Distribution
		( cd ${DIST}/flat && xar --compression none -cf "../${APPNAME}.pkg" * )
		chmod +x "${DIST}/${APPNAME}.pkg"

PHONY: clean
clean:
		rm -rf ${DIST}
