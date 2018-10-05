VERSION = $(shell cat ../../datashare/pom.xml | grep '<version>[0-9.]\+' | sed 's/<version>\([0-9.]\+\)<\/version>/\1/g' | tr -d '[:space:]')
DIST_TARGET=dist

clean:
		rm -rf dist
# cf http://bomutils.dyndns.org/tutorial.html
dist: 
		mkdir -p dist/flat/base.pkg dist/flat/Resources/en.lproj dist/root/Applications
		./build/appify ../../datashare/datashare-dist/src/main/datashare.sh "Datashare ${VERSION}"
		mv "Datashare ${VERSION}.app" dist/root/Applications/
		( find dist/root | cpio -o --format odc --owner 0:80 | gzip -c ) > dist/flat/base.pkg/Payload
		cp PackageInfo dist/flat/base.pkg/
		NB_FILES=$(find build/root | wc -l)
		SIZE=$(du -b -s dist/root)
		( find scripts | cpio -o --format odc --owner 0:80 | gzip -c ) > dist/flat/base.pkg/Scripts
		mkbom -u 0 -g 80 dist/root dist/flat/base.pkg/Bom
		cp Distribution dist/flat
		xar --compression none -cf "dist/Datashare ${VERSION}.pkg" dist/flat/*
