export DIST=dist

$(DIST):
		mkdir -p $(DIST)

$(DIST)/datashare.sh: $(DIST)
		cp datashare.sh $(DIST)
		sed -i 's/__version__/"${VERSION}"/g' ${DIST}/datashare.sh

PHONY: clean
clean:
		rm -rf ${DIST}
