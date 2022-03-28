DOCKER_REGISTRY := docker.dragonfly.co.nz
GIT_REPO := $(shell basename `git rev-parse --show-toplevel` | tr '[:upper:]' '[:lower:]')
IMAGE := $(DOCKER_REGISTRY)/$(GIT_REPO)
RUN ?= docker run $(DOCKER_ARGS) --rm -v $$(pwd):/home/kaimahi/${GIT_REPO} -w /home/kaimahi/${GIT_REPO} -u $(UID):$(GID) $(IMAGE)
UID ?= kaimahi
GID ?= kaimahi
DOCKER_ARGS ?=
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')

all:
	$(RUN) Rscript build.R

r_shell: DOCKER_ARGS= -dit --rm -e DISPLAY=$$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:ro --name="rdev"
r_shell:
	$(RUN) R

.PHONY: docker
docker:
	docker build $(DOCKER_ARGS) --tag $(IMAGE):$(GIT_TAG) .
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

.PHONY: docker-push
docker-push:
	docker push $(IMAGE):$(GIT_TAG)
	docker push $(IMAGE):latest

.PHONY: docker-pull
docker-pull:
	docker pull $(IMAGE):$(GIT_TAG)
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

.PHONY: enter
enter: DOCKER_ARGS=-it
enter:
	$(RUN) bash

.PHONY: enter-root
enter-root: DOCKER_ARGS=-it
enter-root: UID=root
enter-root: GID=root
enter-root:
	$(RUN) bash
