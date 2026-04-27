ARG ARCH="amd64"
ARG OS="linux"
FROM quay.io/prometheus/busybox-${OS}-${ARCH}:latest@sha256:35e7e430350711653810b2b3cc889fec2a6e0175c078e4114964c7252c411209

ARG ARCH="amd64"
ARG OS="linux"
COPY .build/${OS}-${ARCH}/snowflake-exporter /bin/snowflake-exporter

EXPOSE      9975
USER        nobody
ENTRYPOINT  [ "/bin/snowflake-exporter" ]
