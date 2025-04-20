SHELL := /bin/bash

gittagname := $(shell git describe --abbrev=0 --tags)
gitcommit := $(shell  git rev-parse --short HEAD)
versiondate := $(shell date +%Y%m%d%H%M%S)

ifeq ($(origin VERSION), undefined)
  ifneq ($(strip $(gittagname)),)
    VERSION := $(gittagname)
  else ifneq ($(strip $(gitcommit)),)
    VERSION := $(gitcommit)
  else
    VERSION := $(versiondate)
  endif
else
  ifneq ($(strip $(gitcommit)),)
    VERSION := $(VERSION)-$(gitcommit)
  endif
endif

.PHONY: all abcore-main abcore-test abiot-main abiot-test build_chain clean check

all: abcore-main abcore-test abiot-main abiot-test

abcore-main:
	@$(MAKE) build_chain CHAIN=abcore NETWORK=mainnet

abcore-test:
	@$(MAKE) build_chain CHAIN=abcore NETWORK=testnet

abiot-main:
	@$(MAKE) build_chain CHAIN=abiot NETWORK=mainnet

abiot-test:
	@$(MAKE) build_chain CHAIN=abiot NETWORK=testnet

build_chain:
	@echo "🔨 Building ${CHAIN} ${NETWORK}..."
	@echo "Version: ${VERSION}"
	@bash build.sh ${VERSION} "${CHAIN}" "${NETWORK}"
	@echo "✅ Done: ${CHAIN} ${NETWORK} built."
	@echo "👉 To install: run 'cd ./build/${CHAIN}/${NETWORK} && sudo bash newchain.sh'"
	@echo

clean:
	rm -r build/
	@echo "🧹 Cleaned build/ directory."

check:
	@[ "${VERSION}" ] && echo "VERSION is $(VERSION)" || ( echo "VERSION is not set"; exit 1 )