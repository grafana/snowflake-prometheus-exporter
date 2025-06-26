# snowflake-prometheus-exporter

Exports [Snowflake](www.snowflake.com) warehouse, database, table, and replication statistics for a Snowflake account via HTTP for Prometheus consumption.

## Configuration

### Command line flags

The exporter may be configured through its command line flags:

```
  -h, --help                          Show context-sensitive help (also try --help-long and --help-man).
      --web.listen-address=:9975 ...  Addresses on which to expose metrics and web interface. Repeatable for multiple addresses.
      --web.telemetry-path="/metrics" Path under which to expose metrics.
      --account=ACCOUNT               The account to collect metrics for.
      --username=USERNAME             The username for the user used when querying metrics.
      --password=PASSWORD             The password for the user used when querying metrics.
      --private-key-path              The path to the user's RSA private key file.
      --private-key-password          The password for the user's RSA private key.
      --role="ACCOUNTADMIN"           The role to use when querying metrics.
      --warehouse=WAREHOUSE           The warehouse to use when querying metrics.
      --exclude-deleted-tables        Exclude deleted tables when collecting table storage metrics.
      --enable-tracing                Enable trace logging for Snowflake connections.
      --version                       Show application version.
      --log.level=info                Only log messages with the given severity or above. One of: [debug, info, warn, error]
      --log.format=logfmt             Output format of log messages. One of: [logfmt, json]
```

Example usage:

```sh
./snowflake-exporter --account=XXXXXXX-YYYYYYY --username=USERNAME --password=PASSWORD --warehouse=WAREHOUSE --role=ACCOUNTADMIN
```

Example usage (with private key):

```sh
./snowflake-exporter --account=XXXXXXX-YYYYYYY --username=USERNAME --private-key-path=./PRIVATE_KEY.p8 --warehouse=WAREHOUSE --role=ACCOUNTADMIN
```

_If both password and private key file are specified, the private key takes precedence._

### Environment Variables

Alternatively, the exporter may be configured using environment variables:

| Name                                    | Description                                                                      |
| --------------------------------------- | -------------------------------------------------------------------------------- |
| SNOWFLAKE_EXPORTER_ACCOUNT              | The account to collect metrics for.                                              |
| SNOWFLAKE_EXPORTER_USERNAME             | The username for the user used when querying metrics.                            |
| SNOWFLAKE_EXPORTER_PASSWORD             | The password for the user used when querying metrics.                            |
| SNOWFLAKE_EXPORTER_PRIVATE_KEY_PATH     | The path to the user's RSA private key file.                                     |
| SNOWFLAKE_EXPORTER_PRIVATE_KEY_PASSWORD | The password for the user's RSA private key (not required for unencrypted keys). |
| SNOWFLAKE_EXPORTER_ROLE                 | The role to use when querying metrics.                                           |
| SNOWFLAKE_EXPORTER_WAREHOUSE            | The warehouse to use when querying metrics.                                      |
| SNOWFLAKE_EXPORTER_ENABLE_TRACING       | Enable trace logging for Snowflake connections.                                  |
| SNOWFLAKE_EXPORTER_WEB_TELEMETRY_PATH   | Path under which to expose metrics.                                              |

Example usage:

```sh
SNOWFLAKE_EXPORTER_ACCOUNT=XXXXXXX-YYYYYYY \
SNOWFLAKE_EXPORTER_USERNAME=USERNAME \
SNOWFLAKE_EXPORTER_PASSWORD=PASSWORD \
SNOWFLAKE_EXPORTER_ROLE=ACCOUNTADMIN \
SNOWFLAKE_EXPORTER_WAREHOUSE=WAREHOUSE \
./snowflake-exporter
```

Example usage (with private key):

```sh
SNOWFLAKE_EXPORTER_ACCOUNT=XXXXXXX-YYYYYYY \
SNOWFLAKE_EXPORTER_USERNAME=USERNAME \
SNOWFLAKE_EXPORTER_PRIVATE_KEY_PATH=./PRIVATE_KEY.p8 \
SNOWFLAKE_EXPORTER_ROLE=ACCOUNTADMIN \
SNOWFLAKE_EXPORTER_WAREHOUSE=WAREHOUSE \
./snowflake-exporter
```

### RSA Key-Pair Authentication

The exporter supports RSA authentication in place of a password. Follow [this guide](https://docs.snowflake.com/en/user-guide/key-pair-auth) to configure key-pair authentication in your Snowflake environment.

**Note**: The exporter supports both encrypted and unencrypted private keys. Both example usages below are for encrypted keys. For accurate example usages for environments with an unencrypted private key, remove the `--private-key-password` flag or `SNOWFLAKE_EXPORTER_PRIVATE_KEY_PASSWORD` variable respectively.

Example usage (flags):

```sh
./snowflake-exporter --account=XXXXXXX-YYYYYYY --username=USERNAME --private-key-path=/PATH/TO/rsa_key.p8 --private-key-password=PASSWORD --warehouse=WAREHOUSE --role=ACCOUNTADMIN
```

Example usage (environment vars):

```sh
SNOWFLAKE_EXPORTER_ACCOUNT=XXXXXXX-YYYYYYY \
SNOWFLAKE_EXPORTER_USERNAME=USERNAME \
SNOWFLAKE_EXPORTER_PRIVATE_KEY_PATH=/PATH/TO/rsa_key.p8 \
SNOWFLAKE_EXPORTER_PRIVATE_KEY_PASSWORD=RSAPASSWORD \
SNOWFLAKE_EXPORTER_ROLE=ACCOUNTADMIN \
SNOWFLAKE_EXPORTER_WAREHOUSE=WAREHOUSE \
./snowflake-exporter
```

## Troubleshooting

The exporter is susceptible to slow collection times in environments with a large number of deleted tables. For environments experiencing poor performance, enabling `--exclude-deleted-tables` may lead to improved metric processing speed.
