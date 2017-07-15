NS=emacski
REPO=k8s-kibana
VERSION?=latest

GIT_URL?=none
GIT_COMMIT?=none

.PHONY: build push shell run _validate-release release cleanup clean

build-all: build build-proxy

build:
	docker build --pull \
	--build-arg GIT_URL=$(GIT_URL) \
	--build-arg GIT_COMMIT=$(GIT_COMMIT) \
	-t $(NS)/$(REPO):$(VERSION) .

build-proxy:
	echo 'FROM $(NS)/$(REPO):$(VERSION)\n'\
	'ENV KIBANA_BASE_URL=/api/v1/proxy/namespaces/kube-system/services/kibana-logging\n'\
	'RUN kibana-$$KIBANA_VERSION-linux-x86_64/bin/kibana --server.basePath="$$KIBANA_BASE_URL" 2>&1 | grep -m 1 "Optimization .* complete"' \
		> Dockerfile-proxy
	docker build -f Dockerfile-proxy -t $(NS)/$(REPO):$(VERSION)-proxy .
	rm -f Dockerfile-proxy

push:
	docker push $(NS)/$(REPO):$(VERSION)

push-proxy:
	docker push $(NS)/$(REPO):$(VERSION)-proxy

push-all: push push-proxy

shell:
	docker run --rm -ti --entrypoint /bin/sh $(NS)/$(REPO):$(VERSION)

run:
	docker run --rm --init $(NS)/$(REPO):$(VERSION)

_validate-release:
ifeq ($(VERSION),latest)
	$(error VERSION must be specified for release and not be 'latest')
endif

release: _validate-release build-all push-all
	# set latest tag to current release
	docker tag $(NS)/$(REPO):$(VERSION) $(NS)/$(REPO):latest
	docker tag $(NS)/$(REPO):$(VERSION)-proxy $(NS)/$(REPO):latest-proxy
	docker push $(NS)/$(REPO):latest
	docker push $(NS)/$(REPO):latest-proxy

cleanup:
	# remove untagged and dangling images
	@docker image prune -f
	@docker images -f "label=image.name=$(REPO)" | grep "none" && \
	docker rmi $$(docker images -f "label=image.name=$(REPO)" | grep "none" | awk '{print $$3}') || \
	exit 0

clean:
	# remove all images for namespace emacski and repo k8s-kibana
	@docker images -f "label=image.name=$(REPO)" | grep "$(NS)" && \
	docker rmi $$(docker images -f "label=image.name=$(REPO)" | grep "$(NS)" | awk '{print $$3}') || \
	exit 0
