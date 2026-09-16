VERSION ?= $(shell cat VERSION.txt)

.PHONY: help all mac windows stats clean

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

all: mac windows ## Build the macOS and Windows installers

mac: ## Build the macOS installer (mac/dist/datashare-$(VERSION).pkg)
	$(MAKE) -C mac VERSION=$(VERSION) all

windows: ## Build the Windows installer (windows/dist/datashare-$(VERSION).exe)
	$(MAKE) -C windows VERSION=$(VERSION) all

stats: ## Export release download stats to ds_stats.csv
	python3 scripts/stats.py

clean: ## Remove build artifacts
	$(MAKE) -C mac clean
	$(MAKE) -C windows clean
