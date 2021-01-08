DOCKER_REPO = dairiki/exim4-relay
DOCKER_TAG  = $(patsubst ${TAG_PFX}%,%,${GIT_DESC})
IMAGE_NAME  = ${DOCKER_REPO}:${DOCKER_TAG}

TAG_PFX    = smtp-relay_
GIT_DESC  := $(shell git describe --match="${TAG_PFX}*" --tags --dirty --always)
GIT_COMMIT = $(shell git rev-parse HEAD)
GIT_DIRTY  = $(shell git diff --quiet || echo "-dirty")

SRC_FILES := $(filter-out .%,$(shell git ls-files))

BUILD_ARGS = \
    --build-arg SOURCE_VERSION="${GIT_DESC}" \
    --build-arg SOURCE_COMMIT="${GIT_COMMIT}${GIT_DIRTY}" \
    --build-arg BUILD_DATE="$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg BUILDKIT_INLINE_CACHE=1


export SOURCE_VERSION SOURCE_COMMIT BUILD_DATE

DOCKER_BUILDKIT   = 1
#BUILDKIT_PROGRESS = plain
export DOCKER_BUILDKIT BUILDKIT_PROGRESS

# https://www.gnu.org/prep/standards/html_node/Standard-Targets.html
.PHONY: all install check mostlyclean clean distclean

.PHONY: build test down publish tag assert-not-dirty

all: build
install: publish

# Build from scratch if build.stamp does not exist (e.g. after "make clean".)
ifeq ($(realpath build.stamp),)
BUILD_NC = --no-cache --pull
endif

build: build.stamp
build.stamp: ${SRC_FILES}
#	docker-compose build ${BUILD_NC }${BUILD_ARGS}
# My version of docker-compose (1.25.0) doesn't seem to fully use BuildKit
# to speed up builds.  Let's just build manually for now.
	docker build -t ${DOCKER_REPO} --target exim4-relay \
		${BUILD_NC} ${BUILD_ARGS} .
	docker build -t ${DOCKER_REPO}:_test-msa --target test-msa \
		${BUILD_ARGS} .
	@touch $@

test: build check
check:
	docker-compose up sut

mostlyclean down:
	docker-compose down -v
clean: mostlyclean
	rm -f build.stamp
distclean: clean


.PHONY: publish tag assert-not-dirty

publish: tag
	docker push ${IMAGE_NAME}
	docker push ${DOCKER_REPO}

tag: assert-not-dirty build
	docker tag ${DOCKER_REPO} ${IMAGE_NAME}

assert-not-dirty:
	@if ! git diff --quiet; then \
	    echo "ERROR: source tree is dirty" 1>&2; \
	    exit 1; \
	fi
