JSONNET_FMT := jsonnetfmt -n 2 --max-blank-lines 2 --string-style s --comment-style s
DOCKER_ARCHS ?= amd64 armv7 arm64
DOCKER_IMAGE_NAME ?= snowflake-exporter

ALL_SRC := $(shell find . -name '*.go' -o -name 'Dockerfile*' -type f | sort)

# Must precede `include Makefile.common` as it'll otherwise get overwritten
GOLANGCI_LINT_VERSION := v2.12.2
GOVULNCHECK_VERSION ?= 0782b76014f15f24e22a438f30f308df42899ba1 # v1.3.0
GOVULNCHECK          = $(FIRST_GOPATH)/bin/govulncheck

all:: vet common-all security-check

include Makefile.common

.PHONY: vuln-check
vuln-check:
	@echo ">> Running govulncheck..."
	@command -v $(GOVULNCHECK) >/dev/null 2>&1 || { echo "govulncheck not installed. Install: go install golang.org/x/vuln/cmd/govulncheck@$(GOVULNCHECK_VERSION)"; exit 1; }
	$(GOVULNCHECK) ./...
	@echo ">> govulncheck passed!"

.PHONY: gosec-check
gosec-check: $(GOLANGCI_LINT)
	@echo ">> Running gosec via golangci-lint..."
	@command -v $(GOLANGCI_LINT) >/dev/null 2>&1 || { echo "golangci-lint not installed. Install: https://golangci-lint.run/docs/welcome/install/"; exit 1; }
	$(GOLANGCI_LINT) run --enable-only gosec $(pkgs)
	@echo ">> Security checks passed!"

.PHONY: security-check
security-check: vuln-check gosec-check

# Check if .github/workflows/*.yml need to be updated
# when changing the install-ci-deps target.
install-ci-deps:
	go install github.com/google/go-jsonnet/cmd/jsonnet@v0.20.0
	go install github.com/google/go-jsonnet/cmd/jsonnetfmt@v0.20.0
	go install github.com/google/go-jsonnet/cmd/jsonnet-lint@v0.20.0
	go install github.com/monitoring-mixins/mixtool/cmd/mixtool@ea35232b9d85b4cd7943b481c6f90fd94f1ec0ca # main, 2026-05-04 (no release tags published)
	go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.5.1
	go install github.com/grafana/grizzly/cmd/grr@v0.7.1 # latest release, 2025-01-22

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
