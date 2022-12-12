export DIST=dist
export VERSION=${VERSION}
export SCRIPT_NAME=datashare-${VERSION}.sh

all: $(DIST)/$(SCRIPT_NAME)

$(DIST):
		mkdir -p $(DIST)

$(DIST)/$(SCRIPT_NAME): $(DIST)
		cp datashare.sh $(DIST)/$(SCRIPT_NAME)
		sed -i 's/__version__/"${VERSION}"/g' $(DIST)/$(SCRIPT_NAME)

PHONY: clean
clean:
		rm -rf $(DIST)
