# Snowflake Mixin

The Snowflake mixin is a set of configurable Grafana dashboards and alerts based on the [Snowflake exporter](../README.md).

The Snowflake mixin contains the following dashboards:
- Snowflake overview
- Snowflake data ownership

## Snowflake overview
The Snowflake overview dashboard provides details on warehouse activity, login activity, and billing metrics.

![First screenshot of the overview dashboard](https://storage.googleapis.com/grafanalabs-integration-assets/snowflake/screenshots/snowflake_overview_1.png)
![Second screenshot of the overview dashboard](https://storage.googleapis.com/grafanalabs-integration-assets/snowflake/screenshots/snowflake_overview_2.png)
![Third screenshot of the overview dashboard](https://storage.googleapis.com/grafanalabs-integration-assets/snowflake/screenshots/snowflake_overview_3.png)

## Snowflake data ownership
The Snowflake data ownership dashboard provides details on used storage for schemas and tables.

![First screenshot of the data ownership dashboard](https://storage.googleapis.com/grafanalabs-integration-assets/snowflake/screenshots/snowflake_data_ownership_1.png)
![Second screenshot of the data ownership dashboard](https://storage.googleapis.com/grafanalabs-integration-assets/snowflake/screenshots/snowflake_data_ownership_2.png)

## Install tools

```bash
go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
go install github.com/monitoring-mixins/mixtool/cmd/mixtool@latest
```

For linting and formatting, you would also need and `jsonnetfmt` installed. If you
have a working Go development environment, it's easiest to run the following:

```bash
go install github.com/google/go-jsonnet/cmd/jsonnetfmt@latest
```

The files in `dashboards_out` need to be imported
into your Grafana server. The exact details will be depending on your environment.

`prometheus_alerts.yaml` needs to be imported into Prometheus.

## Generate dashboards and alerts

Edit `config.libsonnet` if required and then build JSON dashboard files for Grafana:

```bash
make
```

For more advanced uses of mixins, see
https://github.com/monitoring-mixins/docs.
