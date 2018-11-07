export DIST=dist
export RESOURCES=resources
export VERSION=0.45
export APPNAME=Datashare
export BUNDLE_ID=org.icij.Datashare

$(DIST):
		mkdir $(DIST)

$(DIST)/${APPNAME}.pkg: $(DIST)/Icij.icns
		mkdir -p ${DIST}/flat/base.pkg ${DIST}/flat/Resources/en.lproj ${DIST}/root/Applications
		./build/gen_file datashare.sh ${DIST}/datashare.sh
		./build/appify ${DIST}/datashare.sh "${APPNAME}"

		# adds icon
		mkdir -p "${APPNAME}.app"/Resources
		cp $(DIST)/Icij.icns "${APPNAME}.app"/Resources/
		cp $(RESOURCES)/Info.plist "${APPNAME}.app"

		mv "${APPNAME}.app" ${DIST}/root/Applications/

		# cf http://bomutils.dyndns.org/tutorial.html
		( cd ${DIST}/root && find . | cpio -o --format odc --owner 0:80 | gzip -c ) > ${DIST}/flat/base.pkg/Payload
		./build/gen_file PackageInfo ${DIST}/flat/base.pkg/PackageInfo
		( cd scripts && find * | cpio -o --format odc --owner 0:80 | gzip -c ) > ${DIST}/flat/base.pkg/Scripts
		( cd ${DIST} && mkbom -u 0 -g 80 root flat/base.pkg/Bom )
		./build/gen_file Distribution ${DIST}/flat/Distribution
		( cd ${DIST}/flat && xar --compression none -cf "../${APPNAME}.pkg" * )
		chmod +x "${DIST}/${APPNAME}.pkg"

$(DIST)/Icij.icns: $(DIST)
		convert -resize 256x256 $(RESOURCES)/icij.png $(DIST)/Icij_256px.png
		convert -resize 128x128 $(RESOURCES)/icij.png $(DIST)/Icij_128px.png
		convert -resize 48x48 $(RESOURCES)/icij.png $(DIST)/Icij_48px.png
		convert -resize 32x32 $(RESOURCES)/icij.png $(DIST)/Icij_32px.png
		convert -resize 16x16 $(RESOURCES)/icij.png $(DIST)/Icij_16px.png
		png2icns $(DIST)/Icij.icns $(DIST)/Icij_*px.png

PHONY: clean
clean:
		rm -rf ${DIST}
