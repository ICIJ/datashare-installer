export DIST=dist
export RESOURCES=resources
export VERSION=${VERSION}
export APPNAME=Datashare
export BUNDLE_ID=org.icij.Datashare
export P12_PASSWORD=password

all: $(DIST)/datashare.pkg $(DIST)/datashareStandalone.pkg

$(DIST):
		mkdir -p $(DIST)/images

$(DIST)/%.pkg: %.sh $(DIST)/Datashare.icns
		mkdir -p $(DIST)/$*/flat/base.pkg $(DIST)/$*/flat/Resources/en.lproj $(DIST)/$*/root/Applications $(DIST)/scripts
		cp $*.sh $(DIST)/$*
		sed -i 's/__version__/"${VERSION}"/g' $(DIST)/$*/$*.sh
		./build/appify $(DIST)/$*/$*.sh "${APPNAME}"

		# adds icon
		mkdir -p "${APPNAME}.app"/Contents/Resources
		cp $(DIST)/Datashare.icns "${APPNAME}.app"/Contents/Resources/
		cp $(RESOURCES)/Info.plist "${APPNAME}.app"/Contents

		mv "${APPNAME}.app" $(DIST)/$*/root/Applications/

		# cf http://bomutils.dyndns.org/tutorial.html
		$(eval export PREINSTALL=pre$*)
		$(eval export POSTINSTALL=post$*)
		cp -a scripts $(DIST)
		sed -i 's/__version__/"${VERSION}"/g' $(DIST)/scripts/postdatashareStandalone
		( cd $(DIST)/scripts/ && find . | cpio -o --format odc --owner 0:80 | gzip -c ) > $(DIST)/$*/flat/base.pkg/Scripts
		( cd $(DIST)/$*/root && find . | cpio -o --format odc --owner 0:80 | gzip -c ) > $(DIST)/$*/flat/base.pkg/Payload
		./build/gen_file PackageInfo $(DIST)/$*/flat/base.pkg/PackageInfo $(DIST)/$*
		( cd $(DIST)/$* && mkbom -u 0 -g 80 root flat/base.pkg/Bom )
		./build/gen_file Distribution $(DIST)/$*/flat/Distribution
		( cd $(DIST)/$*/flat && xar --compression none -cf "../${APPNAME}.pkg" * )
		chmod +x "$(DIST)/$*/${APPNAME}.pkg"

		# signing cf http://users.wfu.edu/cottrell/productsign/productsign_linux.html	
		@echo "$$DATASHARE_PEM_B64" | base64 --decode > /tmp/datashare.pem
		@echo "$$ICIJ_CERT_B64" | base64 --decode > /tmp/icij.crt
		@echo "$$P12_PASSWORD" > /tmp/key.p12.password
		@echo "$$APPSTORE_PRIVATE_KEY_B64" | base64 --decode > /tmp/appstore_private_key.asc
		openssl pkcs12 -export -password pass:$(P12_PASSWORD) -in /tmp/icij.crt -inkey /tmp/datashare.pem -name 'Datashare' -out /tmp/key.p12
		rcodesign sign --p12-file /tmp/key.p12 --p12-password-file /tmp/key.p12.password "$(DIST)/$*/${APPNAME}.pkg"
		rcodesign encode-app-store-connect-api-key -o /tmp/api.json $(APPSTORE_ISSUER_ID) $(APPSTORE_KEY_ID) /tmp/appstore_private_key.asc
		rcodesign notary-submit --api-key-path /tmp/api.json --staple "$(DIST)/$*/${APPNAME}.pkg"	
		rm -f /tmp/datashare.pem /tmp/icij.crt /tmp/key.p12 /tmp/key.p12.password /tmp/e.json
		mv $(DIST)/$*/$(APPNAME).pkg $@

$(DIST)/Datashare.icns: $(DIST)
		convert -resize 256x256 $(RESOURCES)/datashare.png $(DIST)/images/Datashare_256px.png
		convert -resize 128x128 $(RESOURCES)/datashare.png $(DIST)/images/Datashare_128px.png
		convert -resize 48x48 $(RESOURCES)/datashare.png $(DIST)/images/Datashare_48px.png
		convert -resize 32x32 $(RESOURCES)/datashare.png $(DIST)/images/Datashare_32px.png
		convert -resize 16x16 $(RESOURCES)/datashare.png $(DIST)/images/Datashare_16px.png
		png2icns $(DIST)/Datashare.icns $(DIST)/images/Datashare_*px.png

PHONY: clean
clean:
		rm -rf ${DIST}
		rm -rf Datashare.app/
