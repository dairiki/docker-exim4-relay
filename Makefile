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
BUILDKIT_PROGRESS = plain
export DOCKER_BUILDKIT BUILDKIT_PROGRESS

# https://www.gnu.org/prep/standards/html_node/Standard-Targets.html
.PHONY: all install check mostlyclean clean distclean

.PHONY: build test down publish tag assert-not-dirty

all: build
install: publish

build: build.stamp
build.stamp: ${SRC_FILES}
# Build from scratch if build.stamp does not exist (e.g. after "make clean".)
ifeq ($(realpath build.stamp),)
# Just build the main image from scratch.
# Otherwise the test image build totally from scratch, too (it doesn't
# use the cached intermediate 'base' stage.)
	docker build -t ${DOCKER_REPO} --target exim4-relay \
		--no-cache --pull ${BUILD_ARGS} .
endif
	docker-compose build ${BUILD_ARGS}
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
