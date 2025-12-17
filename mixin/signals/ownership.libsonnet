// For dashboard signals we use last_over_time(metric{}[24h]) to use only the most recent, complete data; this helps users who have long time between scrape intervals to see data.
// Alerts aggregate and evaluate last_over_time(metric{}[1h]) to use only the most recent, complete data; this helps avoid alerts based on outdated, missing, or partial datapoints due to scrape intervals or service interruptions.

function(this) {
  local aggregationLabels = std.join(',', this.instanceLabels + this.ownershipLabels),
  local legendCustomTemplate = '{{instance}}' + if std.length(this.ownershipLabels) > 0 then ' - ' + std.join(' - ', std.map(function(label) '{{' + label + '}}', this.ownershipLabels)) else '',
  filteringSelector: this.filteringSelector,
  groupLabels: this.groupLabels,
  instanceLabels: this.instanceLabels,
  legendCustomTemplate: legendCustomTemplate,
  enableLokiLogs: false,  // Snowflake does not gather logs
  aggLevel: 'none',
  aggFunction: 'avg',
  alertsInterval: '5m',
  discoveryMetric: {
    prometheus: 'snowflake_warehouse_executed_queries',
  },
  signals: {
    activeSchemaOwnedData: {
      name: 'Active schema owned data',
      nameShort: 'Active schema data',
      description: 'Amount of active data owned by the selected schema.',
      type: 'raw',
      unit: 'bytes',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ') (last_over_time(snowflake_table_active_bytes{%(queriesSelector)s, database_name=~"$database_name", schema_name=~"$schema_name"}[24h]))',
        },
      },
    },

    timeTravelSchemaOwnedData: {
      name: 'Time travel schema owned data',
      nameShort: 'Time travel schema data',
      description: 'Amount of time travel data owned by the selected schema.',
      type: 'raw',
      unit: 'bytes',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ') (last_over_time(snowflake_table_time_travel_bytes{%(queriesSelector)s, database_name=~"$database_name", schema_name=~"$schema_name"}[24h]))',
        },
      },
    },

    failsafeSchemaOwnedData: {
      name: 'Fail-safe schema owned data',
      nameShort: 'Fail-safe schema data',
      description: 'Amount of fail-safe data owned by the selected schema.',
      type: 'raw',
      unit: 'bytes',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ') (last_over_time(snowflake_table_failsafe_bytes{%(queriesSelector)s, database_name=~"$database_name", schema_name=~"$schema_name"}[24h]))',
        },
      },
    },

    cloneSchemaOwnedData: {
      name: 'Clone schema owned data',
      nameShort: 'Clone schema data',
      description: 'Amount of clone data owned by the selected schema.',
      type: 'raw',
      unit: 'bytes',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ') (last_over_time(snowflake_table_clone_bytes{%(queriesSelector)s, database_name=~"$database_name", schema_name=~"$schema_name"}[24h]))',
        },
      },
    },

    top5LargestTables: {
      name: 'Top 5 largest tables',
      nameShort: 'Top 5 largest tables',
      description: 'The top 5 largest tables that belong to the selected schema.',
      type: 'raw',
      unit: 'bytes',
      sources: {
        prometheus: {
          expr: 'last_over_time(snowflake_table_active_bytes{%(queriesSelector)s, database_name=~"$database_name", schema_name=~"$schema_name"}[24h])',
        },
      },
    },

    deletedTables: {
      name: 'Deleted tables',
      nameShort: 'Deleted tables',
      description: 'The number of tables that have been purged from storage.',
      type: 'raw',
      unit: 'none',
      sources: {
        prometheus: {
          expr: 'snowflake_table_deleted_tables{%(queriesSelector)s}',
          legendCustomTemplate: legendCustomTemplate,
        },

      },
    },

    activeTableOwnedData: {
      name: 'Active table owned data',
      nameShort: 'Active table data',
      description: 'Amount of active data owned by the selected table.',
      type: 'raw',
      unit: 'bytes',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ', table_name) (last_over_time(snowflake_table_active_bytes{%(queriesSelector)s, database_name=~"$database_name", schema_name=~"$schema_name", table_name=~"$table_name"}[24h]))',
          legendCustomTemplate: legendCustomTemplate + ' - {{table_name}}',
        },
      },
    },

    timeTravelTableOwnedData: {
      name: 'Time travel table owned data',
      nameShort: 'Time travel table data',
      description: 'Amount of time travel data owned by the selected table.',
      type: 'raw',
      unit: 'bytes',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ', table_name) (last_over_time(snowflake_table_time_travel_bytes{%(queriesSelector)s, database_name=~"$database_name", schema_name=~"$schema_name", table_name=~"$table_name"}[24h]))',
          legendCustomTemplate: legendCustomTemplate + ' - {{table_name}}',
        },
      },
    },

    failsafeTableOwnedData: {
      name: 'Fail-safe table owned data',
      nameShort: 'Fail-safe table data',
      description: 'Amount of fail-safe data owned by the selected table.',
      type: 'raw',
      unit: 'bytes',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ', table_name) (last_over_time(snowflake_table_failsafe_bytes{%(queriesSelector)s, database_name=~"$database_name", schema_name=~"$schema_name", table_name=~"$table_name"}[24h]))',
          legendCustomTemplate: legendCustomTemplate + ' - {{table_name}}',
        },
      },
    },

    cloneTableOwnedData: {
      name: 'Clone table owned data',
      nameShort: 'Clone table data',
      description: 'Amount of clone data owned by the selected table.',
      type: 'raw',
      unit: 'bytes',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ', table_name) (last_over_time(snowflake_table_clone_bytes{%(queriesSelector)s, database_name=~"$database_name", schema_name=~"$schema_name", table_name=~"$table_name"}[24h]))',
          legendCustomTemplate: legendCustomTemplate + ' - {{table_name}}',
        },
      },
    },
  },
}
