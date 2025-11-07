function(this) {
  local legendCustomTemplate = '{{instance}}',
  local aggregationLabels = std.join(',', ['job', 'instance']),
  filteringSelector: this.filteringSelector,
  groupLabels: this.groupLabels,
  instanceLabels: this.instanceLabels,
  enableLokiLogs: false,  // Snowflake does not gather logs
  legendCustomTemplate: legendCustomTemplate,
  aggLevel: 'none',
  aggFunction: 'avg',
  alertsInterval: '5m',
  discoveryMetric: {
    prometheus: 'snowflake_table_active_bytes',
  },
  signals: {
    warehouseActivityExecutedQueries: {
      name: 'Warehouse activity executed queries',
      nameShort: 'Warehouse activity executed queries',
      description: 'The number of executed queries for the selected warehouse.',
      type: 'raw',
      unit: 'percentunit',
      sources: {
        prometheus: {
          expr: 'snowflake_warehouse_executed_queries{%(queriesSelector)s, name=~"$warehouse"}',
          legendCustomTemplate: '{{instance}} - {{name}} - Executed query load',
        },
      },
    },

    warehouseActivityOverloadedQueueLoad: {
      name: 'Warehouse activity overloaded queue load',
      nameShort: 'Warehouse activity overloaded queue load',
      description: 'The number of overloaded queue load for the selected warehouse.',
      type: 'raw',
      unit: 'percentunit',
      sources: {
        prometheus: {
          expr: 'snowflake_warehouse_overloaded_queue_size{%(queriesSelector)s, name=~"$warehouse"}',
          legendCustomTemplate: '{{instance}} - {{name}} - Overloaded queue load',
        },
      },
    },

    warehouseActivityProvisioningQueueLoad: {
      name: 'Warehouse activity provisioning queue load',
      nameShort: 'Warehouse activity provisioning queue load',
      description: 'The number of provisioning queue load for the selected warehouse.',
      type: 'raw',
      unit: 'percentunit',
      sources: {
        prometheus: {
          expr: 'snowflake_warehouse_provisioning_queue_size{%(queriesSelector)s, name=~"$warehouse"}',
          legendCustomTemplate: '{{instance}} - {{name}} - Provisioning queue load',
        },
      },
    },

    warehouseActivityBlockedQueryLoad: {
      name: 'Warehouse activity blocked query load',
      nameShort: 'Warehouse activity blocked query load',
      description: 'The number of blocked query load for the selected warehouse.',
      type: 'raw',
      unit: 'percentunit',
      sources: {
        prometheus: {
          expr: 'snowflake_warehouse_blocked_queries{%(queriesSelector)s, name=~"$warehouse"}',
          legendCustomTemplate: '{{instance}} - {{name}} - Blocked query load',
        },
      },
    },

    accountStorageUsage: {
      name: 'Account storage usage',
      nameShort: 'Account storage usage',
      description: 'The storage usage for the account.',
      type: 'raw',
      unit: 'bytes',
      sources: {
        prometheus: {
          expr: 'snowflake_storage_bytes{%(queriesSelector)s}',
          legendCustomTemplate: '{{instance}} - Storage',
        },
      },
    },

    accountStageUsage: {
      name: 'Account stage usage',
      nameShort: 'Account stage usage',
      description: 'The stage usage for the account.',
      type: 'gauge',
      unit: 'bytes',
      sources: {
        prometheus: {
          expr: 'snowflake_stage_bytes{%(queriesSelector)s}',
          legendCustomTemplate: '{{instance}} - Stage',
        },
      },
    },

    accountFailsafeUsage: {
      name: 'Account failsafe usage',
      nameShort: 'Account failsafe usage',
      description: 'The failsafe usage for the account.',
      type: 'gauge',
      unit: 'bytes',
      sources: {
        prometheus: {
          expr: 'snowflake_failsafe_bytes{%(queriesSelector)s}',
          legendCustomTemplate: '{{instance}} - Failsafe',
        },
      },
    },

    loginAttemptsTotal: {
      name: 'Login attempts total',
      nameShort: 'Login attempts total',
      description: 'The total number of login attempts for the account.',
      type: 'raw',
      unit: 'logins/hr',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ') (snowflake_login_rate{%(queriesSelector)s})',
          legendCustomTemplate: '{{instance}} - Total',
        },
      },
    },

    loginAttemptsFailed: {
      name: 'Login attempts failed',
      nameShort: 'Login attempts failed',
      description: 'The number of failed login attempts for the account.',
      type: 'raw',
      unit: 'logins/hr',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ') (snowflake_failed_login_rate{%(queriesSelector)s})',
          legendCustomTemplate: '{{instance}} - Failed',
        },
      },
    },

    loginAttemptsSuccessful: {
      name: 'Login attempts successful',
      nameShort: 'Login attempts successful',
      description: 'The number of successful login attempts for the account.',
      type: 'raw',
      unit: 'logins/hr',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ') (snowflake_successful_login_rate{%(queriesSelector)s})',
          legendCustomTemplate: '{{instance}} - Successful',
        },
      },
    },

    successfulLoginAttempts: {
      name: 'Successful login attempts',
      nameShort: 'Successful login attempts',
      description: 'The percentage of successful login attempts for the account.',
      type: 'raw',
      unit: 'percentunit',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ') (snowflake_successful_login_rate{%(queriesSelector)s}) / sum by (' + aggregationLabels + ') (snowflake_login_rate{%(queriesSelector)s})',
          legendCustomTemplate: '{{instance}} - Successful',
        },
      },
    },

    failedLoginAttempts: {
      name: 'Failed login attempts',
      nameShort: 'Failed login attempts',
      description: 'The percentage of failed login attempts for the account.',
      type: 'raw',
      unit: 'percentunit',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ') (snowflake_failed_login_rate{%(queriesSelector)s}) / sum by (' + aggregationLabels + ') (snowflake_login_rate{%(queriesSelector)s})',
          legendCustomTemplate: '{{instance}} - Failed',
        },
      },
    },

    usedComputeCredits: {
      name: 'Used compute credits',
      nameShort: 'Used compute credits',
      description: 'Number of compute credits used by the account.',
      type: 'raw',
      unit: 'credits/hr',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ') (snowflake_used_compute_credits{%(queriesSelector)s})',
          legendCustomTemplate: '{{instance}} - Compute',
        },
      },
    },

    usedCloudServicesCredits: {
      name: 'Used cloud services credits',
      nameShort: 'Used cloud services credits',
      description: 'Number of cloud services credits used by the account.',
      type: 'raw',
      unit: 'credits/hr',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ') (snowflake_used_cloud_services_credits{%(queriesSelector)s})',
          legendCustomTemplate: '{{instance}} - Service',
        },
      },
    },

    serviceComputeCreditsUsed: {
      name: 'Service compute credits used',
      nameShort: 'Service compute credits used',
      description: 'The top 5 services that have the highest compute credit usages.',
      type: 'gauge',
      unit: 'credits/hr',
      sources: {
        prometheus: {
          expr: 'snowflake_used_compute_credits{%(queriesSelector)s}',
        },
      },
    },

    serviceCloudServicesCreditsUsed: {
      name: 'Service cloud service credits used',
      nameShort: 'Service cloud service credits used',
      description: 'The top 5 services that have the highest compute credit usages.',
      type: 'gauge',
      unit: 'credits/hr',
      sources: {
        prometheus: {
          expr: 'snowflake_used_cloud_services_credits{%(queriesSelector)s}',
        },
      },
    },

    warehouseComputeCreditsUsed: {
      name: 'Warehouse compute credits used',
      nameShort: 'Warehouse compute credits used',
      description: 'The top 5 warehouses that have the highest compute credit usages.',
      type: 'gauge',
      unit: 'credits/hr',
      sources: {
        prometheus: {
          expr: 'snowflake_warehouse_used_compute_credits{%(queriesSelector)s}',
        },
      },
    },

    warehouseCloudServicesCreditsUsed: {
      name: 'Warehouse cloud services credits used',
      nameShort: 'Warehouse cloud services credits used',
      description: 'The top 5 warehouses that have the highest services credit usages.',
      type: 'gauge',
      unit: 'credits/hr',
      sources: {
        prometheus: {
          expr: 'snowflake_warehouse_used_cloud_service_credits{%(queriesSelector)s}',
        },
      },
    },

    autoclusteringCreditsUsed: {
      name: 'Autoclustering credits used',
      nameShort: 'Autoclustering credits used',
      description: 'Credits billed for automatic reclustering.',
      type: 'gauge',
      unit: 'credits/hr',
      sources: {
        prometheus: {
          expr: 'snowflake_auto_clustering_credits{%(queriesSelector)s}',
          legendCustomTemplate: '{{database_name}} - {{schema_name}} - {{table_name}}',
        },
      },
    },

    tableAutoclusteringCreditsUsed: {
      name: 'Table autoclustering credits used',
      nameShort: 'Table autoclustering credits used',
      description: 'The top 5 tables that have the highest autoclustering credit usages.',
      type: 'gauge',
      unit: 'credits/hr',
      sources: {
        prometheus: {
          expr: 'snowflake_auto_clustering_credits{%(queriesSelector)s}',
        },
      },
    },

    databaseAutoclusteringCreditsUsed: {
      name: 'Database autoclustering credits used',
      nameShort: 'Database autoclustering credits used',
      description: 'The top 5 databases that have the highest autoclustering credit usages.',
      type: 'raw',
      unit: 'credits/hr',
      sources: {
        prometheus: {
          expr: 'sum by (' + aggregationLabels + ', database_name) (snowflake_auto_clustering_credits{%(queriesSelector)s})',
        },
      },
    },
  },
}
