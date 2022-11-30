# snowflake-prometheus-exporter
Exports [Snowflake](www.snowflake.com) warehouse, database, table, and replication statistics for a Snowflake account via HTTP for Prometheus consumption.


## Configuration
### Command line flags
The exporter may be configured through its command line flags:
```
  -h, --help                 Show context-sensitive help (also try --help-long and --help-man).
      --web.listen-address=:9975 ...  
                             Addresses on which to expose metrics and web interface. Repeatable for multiple addresses.
      --web.config.file=""   [EXPERIMENTAL] Path to configuration file that can enable TLS or authentication.
      --web.telemetry-path="/metrics"  
                             Path under which to expose metrics.
      --account=ACCOUNT      The account to collect metrics for.
      --username=USERNAME    The username for the user used when querying metrics.
      --password=PASSWORD    The password for the user used when querying metrics.
      --role="ACCOUNTADMIN"  The role to use when querying metrics.
      --warehouse=WAREHOUSE  The warehouse to use when querying metrics. If none is specified, the default warehouse for the user will be used.
      --version              Show application version.
      --log.level=info       Only log messages with the given severity or above. One of: [debug, info, warn, error]
      --log.format=logfmt    Output format of log messages. One of: [logfmt, json]
```

Example usage: 
```sh
./snowflake-exporter --account=XXXXXXX-YYYYYYY --username=USERNAME --password=PASSWORD --warehouse=WAREHOUSE --role=ACCOUNTADMIN
```

### Environment Variables
Alternatively, the exporter may be configured using environment variables:

| Name                                  | Description                                                                                                        |
|---------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| SNOWFLAKE_EXPORTER_ACCOUNT            | The account to collect metrics for.                                                                                |
| SNOWFLAKE_EXPORTER_USERNAME           | The username for the user used when querying metrics.                                                              |
| SNOWFLAKE_EXPORTER_PASSWORD           | The password for the user used when querying metrics.                                                              |
| SNOWFLAKE_EXPORTER_ROLE               | The role to use when querying metrics.                                                                             |
| SNOWFLAKE_EXPORTER_WAREHOUSE          | The warehouse to use when querying metrics. If none is specified, the default warehouse for the user will be used. |
| SNOWFLAKE_EXPORTER_WEB_TELEMETRY_PATH | Path under which to expose metrics.                                                                                |

Example usage:
```sh
SNOWFLAKE_EXPORTER_ACCOUNT=XXXXXXX-YYYYYYY \
SNOWFLAKE_EXPORTER_USERNAME=USERNAME \
SNOWFLAKE_EXPORTER_PASSWORD=PASSWORD \
SNOWFLAKE_EXPORTER_ROLE=ACCOUNTADMIN \
SNOWFLAKE_EXPORTER_WAREHOUSE=WAREHOUSE \
./snowflake-exporter
```
