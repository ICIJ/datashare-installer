export DIST=dist
export RESOURCES=resources
export VERSION=${VERSION}
export APPNAME=Datashare
export FLAT_PACKAGE_INSTALLER_NAME=datashare-${VERSION}.pkg

all: $(DIST)/$(FLAT_PACKAGE_INSTALLER_NAME)

$(DIST):
		mkdir -p $(DIST)/images

$(DIST)/$(FLAT_PACKAGE_INSTALLER_NAME): start.sh $(DIST)/Datashare.icns
		mkdir -p $(DIST)/flat/base.pkg $(DIST)/flat/Resources/en.lproj 
		mkdir -p $(DIST)/root/Applications 
		mkdir -p $(DIST)/scripts
		cp start.sh $(DIST)/
		sed -i 's/__version__/"${VERSION}"/g' $(DIST)/start.sh
		./build/appify $(DIST)/start.sh "${APPNAME}"

		# Adds icon
		mkdir -p "${APPNAME}.app"/Contents/Resources
		cp $(DIST)/Datashare.icns "${APPNAME}.app"/Contents/Resources/
		cp $(RESOURCES)/Info.plist "${APPNAME}.app"/Contents

		mv "${APPNAME}.app" $(DIST)/root/Applications/

		# CF http://bomutils.dyndns.org/tutorial.html
		$(eval export PREINSTALL=preinstall)
		$(eval export POSTINSTALL=postinstall)
		cp -a scripts $(DIST)
		sed -i 's/__version__/"${VERSION}"/g' $(DIST)/scripts/postinstall
		( cd $(DIST)/scripts/ && find . | cpio -o --format odc --owner 0:80 | gzip -c ) > $(DIST)/flat/base.pkg/Scripts
		( cd $(DIST)/root && find . | cpio -o --format odc --owner 0:80 | gzip -c ) > $(DIST)/flat/base.pkg/Payload
		./build/gen_file PackageInfo $(DIST)/flat/base.pkg/PackageInfo $(DIST)
		( cd $(DIST) && mkbom -u 0 -g 80 root flat/base.pkg/Bom )
		./build/gen_file Distribution $(DIST)/flat/Distribution
		( cd $(DIST)/flat && xar --compression none -cf "../$(FLAT_PACKAGE_INSTALLER_NAME)" * )
		chmod +x "$(DIST)/$(FLAT_PACKAGE_INSTALLER_NAME)"

		# # Create transient files based on environment variables
		@echo "$$APPSTORE_PRIVATE_KEY_B64" | base64 --decode > /tmp/appstore_private_key.asc
		@echo "$$DATASHARE_CA_P12_B64" | base64 --decode > /tmp/datashare_ca.p12

		# Sign the package
		rcodesign sign --p12-file /tmp/datashare_ca.p12 --p12-password "$(DATASHARE_CA_PASSWORD)" "$(DIST)/$(FLAT_PACKAGE_INSTALLER_NAME)"

		# Generate the APP Store Connect API Key
		rcodesign encode-app-store-connect-api-key -o /tmp/api.json $(APPSTORE_ISSUER_ID) $(APPSTORE_KEY_ID) /tmp/appstore_private_key.asc

		# Submity the package for notarization and staple it
		rcodesign notary-submit --api-key-path /tmp/api.json --staple "$(DIST)/$(FLAT_PACKAGE_INSTALLER_NAME)"

		# Remove keys
		rm -f /tmp/datashare_ca.p12 /tmp/datashare_ca.crt /tmp/key.json

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
