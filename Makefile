DOCKER_ARCHS ?= amd64 armv7 arm64
DOCKER_IMAGE_NAME ?= snowflake-exporter

ALL_SRC := $(shell find . -name '*.go' -o -name 'Dockerfile*' -type f | sort)

all:: vet common-all


include Makefile.common

