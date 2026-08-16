ARG ARCH="amd64"
ARG OS="linux"
# We pin the SHA to the default args, may need to revisit this in the future
FROM quay.io/prometheus/busybox-${OS}-${ARCH}:latest@sha256:d86ce8f332fdb3b84f73d2fb0953f61bc77374668bac32a15a8a79ec2ed8f0a9

ARG ARCH="amd64"
ARG OS="linux"
COPY .build/${OS}-${ARCH}/snowflake-exporter /bin/snowflake-exporter

EXPOSE      9975
USER        nobody
ENTRYPOINT  [ "/bin/snowflake-exporter" ]
