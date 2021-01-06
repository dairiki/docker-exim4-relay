APP_NAME	= smtp-relay
DOCKER_REPO	= dairiki/exim4-relay

TAG_PFX    = ${APP_NAME}_
GIT_TAG    := $(shell git describe --match="${TAG_PFX}*" \
			--tags --dirty --always)
TAG        := $(patsubst ${TAG_PFX}%,%,${GIT_TAG})
DIRTY      := $(shell git diff --quiet || echo "-dirty")
VCS_REF    := $(shell git rev-parse --short HEAD)${DIRTY}
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
IMAGE	   := ${DOCKER_REPO}:${TAG}

export GIT_TAG IMAGE VCS_REF BUILD_DATE

.PHONY: build assert-clean

build:
	sudo -E docker-compose build $(BUILD_NC)

publish: BUILD_NC = --no-cache --pull

.PHONY: publish tag tag-latest tag-version assert-clean assert-tagged

assert-clean:
	@if ! git diff --quiet; then \
	    echo "ERROR: source tree is dirty" 1>&2; \
	    exit 1; \
	fi

assert-tagged: assert-clean
	@if ! git diff --quiet; then \
	    echo "ERROR: source tree is dirty" 1>&2; \
	    exit 1; \
	fi

publish: publish-${TAG} publish-latest
tag: tag-latest tag-${TAG}

.SECONDARY: publish-latest publish-version
publish-%: tag-%
	sudo docker push ${DOCKER_REPO}:$*

tag-${TAG}: assert-clean build
tag-latest: tag-${TAG}
	sudo docker tag ${IMAGE} ${DOCKER_REPO}:latest
