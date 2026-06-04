ARG ARCH="amd64"
ARG OS="linux"
# We pin the SHA to the default args, may need to revisit this in the future
FROM quay.io/prometheus/busybox-${OS}-${ARCH}:latest@sha256:6f197b8d4dcee2d7e1bdeeaa1281113096a7ed205d81a4ea12fd4634de5f673d

ARG ARCH="amd64"
ARG OS="linux"
COPY .build/${OS}-${ARCH}/snowflake-exporter /bin/snowflake-exporter

EXPOSE      9975
USER        nobody
ENTRYPOINT  [ "/bin/snowflake-exporter" ]
