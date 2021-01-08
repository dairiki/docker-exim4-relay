DOCKER_REPO = dairiki/exim4-relay
DOCKER_TAG  = $(patsubst ${TAG_PFX}%,%,${GIT_DESC})
IMAGE_NAME  = ${DOCKER_REPO}:${DOCKER_TAG}

TAG_PFX    = v
GIT_DESC  := $(shell git describe --match="${TAG_PFX}*" --tags --dirty --always)
GIT_COMMIT = $(shell git rev-parse HEAD)
GIT_DIRTY  = $(shell git diff --quiet || echo "-dirty")

SRC_FILES := $(filter-out .% tests/% %.yml %.env,$(shell git ls-files))

BUILD_ARGS = \
    --build-arg SOURCE_VERSION="${GIT_DESC}" \
    --build-arg SOURCE_COMMIT="${GIT_COMMIT}${GIT_DIRTY}" \
    --build-arg BUILD_DATE="$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')"


export SOURCE_VERSION SOURCE_COMMIT BUILD_DATE

DOCKER_BUILDKIT   = 1
#BUILDKIT_PROGRESS = plain
export DOCKER_BUILDKIT BUILDKIT_PROGRESS

# https://www.gnu.org/prep/standards/html_node/Standard-Targets.html
.PHONY: all install check mostlyclean clean distclean

.PHONY: help build build-tests test down publish tag push assert-not-dirty

all: build
install: publish

build: stamp.build
stamp.build: ${SRC_FILES}
#	docker-compose build ${BUILD_NC }${BUILD_ARGS}
# My version of docker-compose (1.25.0) doesn't seem to fully use BuildKit
# to speed up builds.  Let's just build manually for now.
	docker build -t ${DOCKER_REPO} --target exim4-relay \
		${BUILD_NC} ${BUILD_ARGS} .
	@touch $@

build-tests: stamp.build-tests
stamp.build-tests: stamp.build
	docker build -t ${DOCKER_REPO}:_test-msa --target test-msa \
		${BUILD_NC} ${BUILD_ARGS} .
	@touch $@

# Target to force full re-pull adn rebuild without using build-cache
.PHONY: build-nc build-tests-nc
build-nc build-tests-nc:
	rm -f stamp.build stamp.build-tests 
	$(MAKE) BUILD_NC="--no-cache --pull" $(patsubst %-nc,%,$@) 

test: build-tests check
check:
	docker-compose up sut
down:
	docker-compose down -v

mostlyclean: down
clean: mostlyclean
	rm -f stamp.build stamp.build-tests
distclean: clean


.PHONY: publish tag assert-not-dirty

# push tagged image
publish: tag push
	docker push ${IMAGE_NAME}

# push :latest
push: build
	docker push ${DOCKER_REPO}

# tag image
tag: assert-not-dirty build
	docker tag ${DOCKER_REPO} ${IMAGE_NAME}

assert-not-dirty:
	@if ! git diff --quiet; then \
	    echo "ERROR: source tree is dirty" 1>&2; \
	    exit 1; \
	fi
