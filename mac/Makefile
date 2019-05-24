export DIST=dist
export RESOURCES=resources
export VERSION=${VERSION}
export APPNAME=Datashare
export BUNDLE_ID=org.icij.Datashare

$(DIST):
		mkdir -p $(DIST)

$(DIST)/${APPNAME}.pkg: $(DIST)/Datashare.icns
		mkdir -p ${DIST}/flat/base.pkg ${DIST}/flat/Resources/en.lproj ${DIST}/root/Applications
		cp datashare.sh ${DIST}/datashare.sh
		sed -i 's/__version__/"${VERSION}"/g' ${DIST}/datashare.sh
		./build/appify ${DIST}/datashare.sh "${APPNAME}"

		# adds icon
		mkdir -p "${APPNAME}.app"/Contents/Resources
		cp $(DIST)/Datashare.icns "${APPNAME}.app"/Contents/Resources/
		cp $(RESOURCES)/Info.plist "${APPNAME}.app"/Contents

		mv "${APPNAME}.app" ${DIST}/root/Applications/

		# cf http://bomutils.dyndns.org/tutorial.html
		( cd ${DIST}/root && find . | cpio -o --format odc --owner 0:80 | gzip -c ) > ${DIST}/flat/base.pkg/Payload
		./build/gen_file PackageInfo ${DIST}/flat/base.pkg/PackageInfo
		( cd scripts && find * | cpio -o --format odc --owner 0:80 | gzip -c ) > ${DIST}/flat/base.pkg/Scripts
		( cd ${DIST} && mkbom -u 0 -g 80 root flat/base.pkg/Bom )
		./build/gen_file Distribution ${DIST}/flat/Distribution
		( cd ${DIST}/flat && xar --compression none -cf "../${APPNAME}.pkg" * )
		chmod +x "${DIST}/${APPNAME}.pkg"

		# signing cf http://users.wfu.edu/cottrell/productsign/productsign_linux.html
		@echo "$$DATASHARE_PEM" > /tmp/datashare.pem
		@echo "$$ICIJ_CERT" > /tmp/icij.crt
		: | openssl dgst -sign /tmp/datashare.pem -binary | wc -c > ${DIST}/siglen.txt
		openssl x509 -in /tmp/icij.crt -outform der -out ${DIST}/cert.der
		xar --sign -f "${DIST}/${APPNAME}.pkg" --digestinfo-to-sign ${DIST}/digestinfo.dat --sig-size `cat ${DIST}/siglen.txt` --cert-loc ${DIST}/cert.der
		openssl rsautl -sign -inkey /tmp/datashare.pem -in ${DIST}/digestinfo.dat -out ${DIST}/signature.dat
		xar --inject-sig ${DIST}/signature.dat -f "${DIST}/${APPNAME}.pkg"
		rm -f /tmp/datashare.pem /tmp/icij.crt

$(DIST)/Datashare.icns: $(DIST)
		convert -resize 256x256 $(RESOURCES)/datashare.png $(DIST)/Datashare_256px.png
		convert -resize 128x128 $(RESOURCES)/datashare.png $(DIST)/Datashare_128px.png
		convert -resize 48x48 $(RESOURCES)/datashare.png $(DIST)/Datashare_48px.png
		convert -resize 32x32 $(RESOURCES)/datashare.png $(DIST)/Datashare_32px.png
		convert -resize 16x16 $(RESOURCES)/datashare.png $(DIST)/Datashare_16px.png
		png2icns $(DIST)/Datashare.icns $(DIST)/Datashare_*px.png

PHONY: clean
clean:
		rm -rf ${DIST}
