APP_NAME	= exim4-relay
VERSION		= 0.3.1
DOCKER_REPO	= dairiki
BUILD_LABELS	= \
    --label "org.label-schema.version=${VERSION}" \
    --label "org.label-schema.build-date=${BUILD_DATE}" \
    --label "org.label-schema.vcs-ref=${VCS_REF}"

SUDO	= sudo
DOCKER	= $(SUDO) docker

VCS_REF := $(shell git rev-parse --short HEAD)$(shell git diff --quiet || echo "-dirty")
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

.PHONY: build assert-clean

build:
	$(DOCKER) build $(BUILD_NC) ${BUILD_LABELS} -t $(APP_NAME) .

publish: BUILD_NC = --no-cache

.PHONY: publish tag tag-latest tag-version assert-clean

assert-clean:
	@if ! git diff --quiet; then \
	    echo "ERROR: source tree is dirty" 1>&2; \
	    exit 1; \
	fi

publish: publish-version publish-latest
tag: tag-version tag-latest

tag-latest publish-latest: VERSION = latest

.SECONDARY: publish-latest publish-version
publish-%: tag-%
	$(DOCKER) push ${DOCKER_REPO}/${APP_NAME}:${VERSION}

tag-version tag-latest: assert-clean build
	$(DOCKER) tag ${APP_NAME}  ${DOCKER_REPO}/${APP_NAME}:${VERSION}
