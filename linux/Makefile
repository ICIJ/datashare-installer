export DIST=dist

$(DIST):
		mkdir -p $(DIST)

$(DIST)/datashare.sh: $(DIST)
		cp datashare.sh $(DIST)
		sed -i 's/datashare_version=.*/datashare_version='"${VERSION}"'/g' ${DIST}/datashare.sh

PHONY: clean
clean:
		rm -rf ${DIST}
