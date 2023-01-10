{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'SnowflakeAlerts',
        rules: [
          {
            alert: 'SnowflakeWarnHighLoginFailures',
            expr: |||
              100 * sum by (job, instance) (last_over_time(snowflake_failed_login_rate{}[1h])) / sum by (job, instance) (last_over_time(snowflake_login_rate{}[30m]))
              > %(alertsWarningLoginFailures)s
            ||| % $._config,
            'for': '5m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              summary: 'Large login failure rate.',
              description:
                ('{{ printf "%%.2f" $value }}%% of logins have failed on {{$labels.instance}}, ' +
                 'which is above threshold of %(alertsWarningLoginFailures)s%%.') % $._config,
            },
          },
          {
            alert: 'SnowflakeWarnHighComputeCreditUsage',
            expr: |||
              sum by (job, instance) (last_over_time(snowflake_used_compute_credits{}[1h]))
              > 0.8 * %(alertsComputeCreditUsageLimit)s
            ||| % $._config,
            'for': '5m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              summary: 'Compute credit usage is within 20% of the configured limit.',
              description:
                ('Compute credit usage is {{ printf "%%.2f" $value }} credits/hr for {{$labels.instance}}, ' +
                 'which is within 20%% of %(alertsComputeCreditUsageLimit)s credits/hr.') % $._config,
            },
          },
          {
            alert: 'SnowflakeCriticalHighComputeCreditUsage',
            expr: |||
              sum by (job, instance) (last_over_time(snowflake_used_compute_credits{}[1h]))
              > %(alertsComputeCreditUsageLimit)s
            ||| % $._config,
            'for': '5m',
            labels: {
              severity: 'critical',
            },
            annotations: {
              summary: 'Compute credit usage is over the configured limit.',
              description:
                ('Compute credit usage is {{ printf "%%.2f" $value }} credits/hr for {{$labels.instance}}, ' +
                 'which is over %(alertsComputeCreditUsageLimit)s credits/hr.') % $._config,
            },
          },
          {
            alert: 'SnowflakeWarnHighServiceCreditUsage',
            expr: |||
              sum by (job, instance) (last_over_time(snowflake_used_cloud_services_credits{}[1h]))
              > 0.8 * %(alertsServiceCreditUsageLimit)s
            ||| % $._config,
            'for': '5m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              summary: 'Cloud services credit usage is within 20% of the configured limit.',
              description:
                ('Cloud services credit usage is {{ printf "%%.2f" $value }} credits/hr for {{$labels.instance}}, ' +
                 'which is within 20%% of %(alertsServiceCreditUsageLimit)s credits/hr.') % $._config,
            },
          },
          {
            alert: 'SnowflakeCriticalHighServiceCreditUsage',
            expr: |||
              sum by (job, instance) (last_over_time(snowflake_used_cloud_services_credits{}[1h]))
              > %(alertsServiceCreditUsageLimit)s
            ||| % $._config,
            'for': '5m',
            labels: {
              severity: 'critical',
            },
            annotations: {
              summary: 'Compute credit usage is over the configured limit.',
              description:
                ('Cloud services credit usage is {{ printf "%%.2f" $value }} credits/hr for {{$labels.instance}}, ' +
                 'which is over %(alertsServiceCreditUsageLimit)s credits/hr.') % $._config,
            },
          },
          {
            alert: 'SnowflakeDown',
            expr: 'last_over_time(snowflake_up{}[1h]) == 0',
            'for': '5m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              summary: 'Snowflake exporter failed to scrape.',
              description: 'The Snowflake exporter failed to scrape one or more metrics for instance {{$labels.instance}}.',
            },
          },
        ],
      },
    ],
  },
}
