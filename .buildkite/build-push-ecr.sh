#!/usr/bin/env bash
# Build the snowflake-exporter binary (promu / make build), image (Dockerfile), and push to ECR.
# ECR authentication is handled by the ecr Buildkite plugin in pipeline.yaml (login: true).

set -euo pipefail

VERSION="${BUILDKITE_COMMIT:?BUILDKITE_COMMIT is not set}"

ECR_HOST="${ECR_HOST:-460210468233.dkr.ecr.us-east-1.amazonaws.com}"
REPO_NAME="${REPO_NAME:-snowflake-exporter/snowflake-prometheus-exporter}"
IMAGE_DEST="${ECR_HOST}/${REPO_NAME}:${VERSION}"

ANNOTATION_MSG="Building and pushing ${IMAGE_DEST}"
echo "${ANNOTATION_MSG}"
buildkite-agent annotate --style "info" "${ANNOTATION_MSG}" || true

set -x

GO_VER="1.25.0"
if [ ! -x "go/bin/go" ]; then
  echo "Installing Go ${GO_VER} into ./go ..."
  curl -fsSL "https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz" | tar -xz
fi
export PATH="${PWD}/go/bin:${PATH}"
export PATH="$(go env GOPATH)/bin:${PATH}"
go version

go mod download
make build

docker build -t "${IMAGE_DEST}" \
  -f Dockerfile \
  --build-arg ARCH=amd64 \
  --build-arg OS=linux \
  .

docker push "${IMAGE_DEST}"

buildkite-agent annotate --style "success" "Pushed ${IMAGE_DEST}" || true
