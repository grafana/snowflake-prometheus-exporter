ARG ARCH="amd64"
ARG OS="linux"
# We pin the SHA to the default args, may need to revisit this in the future
FROM quay.io/prometheus/busybox-${OS}-${ARCH}:latest@sha256:22334508ab30428b42b6ac8c8fae1e12fda864f84fa6fb5b62fb86d9b9b08887

ARG ARCH="amd64"
ARG OS="linux"
COPY .build/${OS}-${ARCH}/snowflake-exporter /bin/snowflake-exporter

EXPOSE      9975
USER        nobody
ENTRYPOINT  [ "/bin/snowflake-exporter" ]
