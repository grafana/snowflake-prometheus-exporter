JSONNET_FMT := jsonnetfmt -n 2 --max-blank-lines 2 --string-style s --comment-style s
DOCKER_ARCHS ?= amd64 armv7 arm64
DOCKER_IMAGE_NAME ?= snowflake-exporter

ALL_SRC := $(shell find . -name '*.go' -o -name 'Dockerfile*' -type f | sort)

all:: vet common-all


include Makefile.common

# Check if .github/workflows/*.yml need to be updated
# when changing the install-ci-deps target.
install-ci-deps:
	go install github.com/google/go-jsonnet/cmd/jsonnet@v0.20.0
	go install github.com/google/go-jsonnet/cmd/jsonnetfmt@v0.20.0
	go install github.com/google/go-jsonnet/cmd/jsonnet-lint@v0.20.0
	go install github.com/monitoring-mixins/mixtool/cmd/mixtool@main
	go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.5.1
	go install github.com/grafana/grizzly/cmd/grr@latest

fmt:
	@find . -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
			xargs -n 1 -- $(JSONNET_FMT) -i

lint-fmt:
	@RESULT=0; \
	for f in $$(find . -type f \( -name '*.libsonnet' -o -name '*.jsonnet' \) -not -path '*/vendor/*'); do \
			$(JSONNET_FMT) -- "$$f" | diff -u "$$f" -; \
			if [ $$? -ne 0 ]; then \
				RESULT=1; \
			fi; \
	done; \
	exit $$RESULT
