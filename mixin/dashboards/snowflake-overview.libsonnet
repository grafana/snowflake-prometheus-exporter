local g = (import 'grafana-builder/grafana.libsonnet');
local grafana = (import 'grafonnet/grafana.libsonnet');
local dashboard = grafana.dashboard;
local template = grafana.template;
local prometheus = grafana.prometheus;

local dashboardUid = 'snowflake-overview';

local promDatasourceName = 'prometheus_datasource';

local promDatasource = {
  uid: '${%s}' % promDatasourceName,
};

local warehouseActivityPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'snowflake_warehouse_executed_queries{instance=~"$instance", job=~"$job", name=~"$warehouse"}',
      datasource=promDatasource,
      legendFormat='{{instance}} - {{name}} - Executed query load'
    ),
    prometheus.target(
      'snowflake_warehouse_overloaded_queue_size{instance=~"$instance", job=~"$job", name=~"$warehouse"}',
      datasource=promDatasource,
      legendFormat='{{instance}} - {{name}} - Overloaded queue load'
    ),
    prometheus.target(
      'snowflake_warehouse_provisioning_queue_size{instance=~"$instance", job=~"$job", name=~"$warehouse"}',
      datasource=promDatasource,
      legendFormat='{{instance}} - {{name}} - Provisioning queue load'
    ),
    prometheus.target(
      'snowflake_warehouse_blocked_queries{instance=~"$instance", job=~"$job", name=~"$warehouse"}',
      datasource=promDatasource,
      legendFormat='{{instance}} - {{name}} - Blocked query load'
    ),
  ],
  type: 'timeseries',
  title: 'Warehouse activity',
  description: 'Warehouse query activity for the warehouse selected by the Warehouse selector.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        barAlignment: 0,
        drawStyle: 'line',
        fillOpacity: 0,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineInterpolation: 'linear',
        lineStyle: {
          fill: 'solid',
        },
        lineWidth: 1,
        pointSize: 5,
        scaleDistribution: {
          type: 'linear',
        },
        showPoints: 'auto',
        spanNulls: 3600000,
        stacking: {
          group: 'A',
          mode: 'none',
        },
        thresholdsStyle: {
          mode: 'off',
        },
      },
      mappings: [],
      unit: 'percentunit',
    },
    overrides: [],
  },
  options: {
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    tooltip: {
      mode: 'single',
      sort: 'none',
    },
  },
};

local accountStorageUsagePanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'snowflake_storage_bytes{instance=~"$instance", job=~"$job"}',
      datasource=promDatasource,
      legendFormat='{{instance}} - Storage'
    ),
    prometheus.target(
      'snowflake_stage_bytes{instance=~"$instance", job=~"$job"}',
      datasource=promDatasource,
      legendFormat='{{instance}} - Stage'
    ),
    prometheus.target(
      'snowflake_failsafe_bytes{instance=~"$instance", job=~"$job"}',
      datasource=promDatasource,
      legendFormat='{{instance}} - Failsafe'
    ),
  ],
  type: 'timeseries',
  title: 'Account storage usage',
  description: 'Data storage used for the account.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        barAlignment: 0,
        drawStyle: 'line',
        fillOpacity: 0,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineInterpolation: 'linear',
        lineWidth: 1,
        pointSize: 5,
        scaleDistribution: {
          type: 'linear',
        },
        showPoints: 'auto',
        spanNulls: 3600000,
        stacking: {
          group: 'A',
          mode: 'none',
        },
        thresholdsStyle: {
          mode: 'off',
        },
      },
      mappings: [],
      unit: 'bytes',
    },
    overrides: [],
  },
  options: {
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    tooltip: {
      mode: 'single',
      sort: 'none',
    },
  },
};

local loginAttemptsPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (job, instance) (snowflake_login_rate{job=~"$job", instance=~"$instance"})',
      datasource=promDatasource,
      legendFormat='{{instance}} - Total'
    ),
    prometheus.target(
      'sum by (job, instance) (snowflake_failed_login_rate{job=~"$job", instance=~"$instance"})',
      datasource=promDatasource,
      legendFormat='{{instance}} - Failed'
    ),
    prometheus.target(
      'sum by (job, instance) (snowflake_successful_login_rate{job=~"$job", instance=~"$instance"})',
      datasource=promDatasource,
      legendFormat='{{instance}} - Successful'
    ),
  ],
  type: 'timeseries',
  title: 'Login attempts',
  description: 'Login attempt rate over the last 24 hours.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        barAlignment: 0,
        drawStyle: 'line',
        fillOpacity: 0,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineInterpolation: 'linear',
        lineWidth: 1,
        pointSize: 5,
        scaleDistribution: {
          type: 'linear',
        },
        showPoints: 'auto',
        spanNulls: 3600000,
        stacking: {
          group: 'A',
          mode: 'none',
        },
        thresholdsStyle: {
          mode: 'off',
        },
      },
      mappings: [],
      unit: 'logins/hr',
    },
    overrides: [],
  },
  options: {
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    tooltip: {
      mode: 'single',
      sort: 'none',
    },
  },
};

local successfulLoginAttemptsPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (job, instance) (snowflake_successful_login_rate{job=~"$job", instance=~"$instance"}) / sum by (job, instance) (snowflake_login_rate{job=~"$job", instance=~"$instance"})',
      datasource=promDatasource,
      legendFormat='{{instance}}'
    ),
  ],
  type: 'gauge',
  title: 'Successful login attempts',
  description: 'Percentage of total login attempts that were successful.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'thresholds',
      },
      mappings: [],
      max: 1,
      min: 0,
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
          {
            color: 'red',
            value: 0,
          },
          {
            color: 'yellow',
            value: 0.6,
          },
          {
            color: 'green',
            value: 0.8,
          },
        ],
      },
      unit: 'percentunit',
    },
    overrides: [],
  },
  options: {
    orientation: 'auto',
    reduceOptions: {
      calcs: [
        'lastNotNull',
      ],
      fields: '',
      limit: 1,
      values: false,
    },
    showThresholdLabels: false,
    showThresholdMarkers: false,
  },
  pluginVersion: '9.1.7',
};

local failedLoginAttemptsPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (job, instance) (snowflake_failed_login_rate{job=~"$job", instance=~"$instance"}) / sum by (job, instance) (snowflake_login_rate{job=~"$job", instance=~"$instance"})',
      datasource=promDatasource,
      legendFormat='{{instance}}'
    ),
  ],
  type: 'gauge',
  title: 'Failed login attempts',
  description: 'Percentage of total login attempts that failed.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'thresholds',
      },
      mappings: [],
      max: 1,
      min: 0,
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
          {
            color: '#EAB839',
            value: 0.2,
          },
          {
            color: 'red',
            value: 0.4,
          },
        ],
      },
      unit: 'percentunit',
    },
    overrides: [],
  },
  options: {
    orientation: 'auto',
    reduceOptions: {
      calcs: [
        'lastNotNull',
      ],
      fields: '',
      values: false,
    },
    showThresholdLabels: false,
    showThresholdMarkers: false,
  },
  pluginVersion: '9.1.7',
};

local billingRow = {
  datasource: promDatasource,
  targets: [],
  type: 'row',
  title: 'Billing',
  collapsed: false,
};

local averageHourlyCreditsUsedPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (job, instance) (snowflake_used_compute_credits{job=~"$job", instance=~"$instance"})',
      intervalFactor=1,
      datasource=promDatasource,
      legendFormat='{{instance}} - Compute'
    ),
    prometheus.target(
      'sum by (job, instance) (snowflake_used_cloud_services_credits{job=~"$job", instance=~"$instance"})',
      intervalFactor=1,
      datasource=promDatasource,
      legendFormat='{{instance}} - Service'
    ),
  ],
  type: 'barchart',
  title: 'Average hourly credits used',
  description: 'Number of billing credits used by the account.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        fillOpacity: 80,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineWidth: 1,
        scaleDistribution: {
          type: 'linear',
        },
      },
      mappings: [],
      unit: 'credits/hr',
    },
    overrides: [],
  },
  interval: '5m',
  options: {
    barRadius: 0,
    barWidth: 1,
    groupWidth: 0.74,
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    orientation: 'auto',
    showValue: 'auto',
    stacking: 'none',
    tooltip: {
      mode: 'single',
      sort: 'none',
    },
    xField: 'Time',
    xTickLabelRotation: 0,
    xTickLabelSpacing: 0,
  },
};

local top5ServiceComputeCreditsUsedPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'snowflake_used_compute_credits{job=~"$job", instance=~"$instance"}',
      datasource=promDatasource,
      format='table',
      legendFormat='__auto'
    ),
  ],
  type: 'table',
  title: 'Top 5 service compute credits used',
  description: 'The top 5 services that have the highest compute credit usages.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'thresholds',
      },
      custom: {
        align: 'center',
        displayMode: 'auto',
        inspect: false,
      },
      decimals: 2,
      mappings: [],
      unit: 'credits/hr',
    },
    overrides: [],
  },
  options: {
    footer: {
      fields: '',
      reducer: [
        'sum',
      ],
      show: false,
    },
    showHeader: true,
  },
  pluginVersion: '9.1.7',
  transformations: [
    {
      id: 'groupBy',
      options: {
        fields: {
          Value: {
            aggregations: [
              'last',
            ],
            operation: 'aggregate',
          },
          instance: {
            aggregations: [],
            operation: 'groupby',
          },
          service: {
            aggregations: [],
            operation: 'groupby',
          },
          service_type: {
            aggregations: [],
            operation: 'groupby',
          },
        },
      },
    },
    {
      id: 'sortBy',
      options: {
        fields: {},
        sort: [
          {
            desc: true,
            field: 'Value (last)',
          },
        ],
      },
    },
    {
      id: 'limit',
      options: {
        limitField: 5,
      },
    },
    {
      id: 'organize',
      options: {
        excludeByName: {},
        indexByName: {},
        renameByName: {
          'Value (last)': 'Credits',
          instance: 'Instance',
          service: 'Service',
          service_type: 'Service Type',
        },
      },
    },
  ],
};

local top5ServiceCloudServiceCreditsUsedPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'snowflake_used_cloud_services_credits{job=~"$job", instance=~"$instance"}',
      datasource=promDatasource,
      format='table',
      legendFormat='__auto'
    ),
  ],
  type: 'table',
  title: 'Top 5 service cloud service credits used',
  description: 'The top 5 services that have the highest compute credit usages.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'thresholds',
      },
      custom: {
        align: 'auto',
        displayMode: 'auto',
        inspect: false,
      },
      decimals: 2,
      mappings: [],
      unit: 'credits/hr',
    },
    overrides: [],
  },
  options: {
    footer: {
      fields: '',
      reducer: [
        'sum',
      ],
      show: false,
    },
    showHeader: true,
  },
  pluginVersion: '9.1.7',
  transformations: [
    {
      id: 'groupBy',
      options: {
        fields: {
          Value: {
            aggregations: [
              'last',
            ],
            operation: 'aggregate',
          },
          instance: {
            aggregations: [],
            operation: 'groupby',
          },
          service: {
            aggregations: [],
            operation: 'groupby',
          },
          service_type: {
            aggregations: [],
            operation: 'groupby',
          },
        },
      },
    },
    {
      id: 'sortBy',
      options: {
        fields: {},
        sort: [
          {
            desc: true,
            field: 'Value (last)',
          },
        ],
      },
    },
    {
      id: 'limit',
      options: {
        limitField: 5,
      },
    },
    {
      id: 'organize',
      options: {
        excludeByName: {},
        indexByName: {},
        renameByName: {
          'Value (last)': 'Credits',
          instance: 'Instance',
          service: 'Service',
          service_type: 'Service Type',
        },
      },
    },
  ],
};

local top5WarehouseComputeCreditsUsedPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'snowflake_warehouse_used_compute_credits{job=~"$job", instance=~"$instance"}',
      datasource=promDatasource,
      format='table',
      legendFormat='__auto'
    ),
  ],
  type: 'table',
  title: 'Top 5 warehouse compute credits used',
  description: 'The top 5 warehouses that have the highest compute credit usages.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'thresholds',
      },
      custom: {
        align: 'center',
        displayMode: 'auto',
        inspect: false,
      },
      mappings: [],
      unit: 'credits/hr',
    },
    overrides: [],
  },
  options: {
    footer: {
      fields: '',
      reducer: [
        'sum',
      ],
      show: false,
    },
    showHeader: true,
  },
  pluginVersion: '9.1.7',
  transformations: [
    {
      id: 'groupBy',
      options: {
        fields: {
          Value: {
            aggregations: [
              'last',
            ],
            operation: 'aggregate',
          },
          instance: {
            aggregations: [],
            operation: 'groupby',
          },
          name: {
            aggregations: [],
            operation: 'groupby',
          },
        },
      },
    },
    {
      id: 'sortBy',
      options: {
        fields: {},
        sort: [
          {
            desc: true,
            field: 'Value (last)',
          },
        ],
      },
    },
    {
      id: 'limit',
      options: {
        limitField: 5,
      },
    },
    {
      id: 'organize',
      options: {
        excludeByName: {},
        indexByName: {},
        renameByName: {
          'Value (last)': 'Credits',
          instance: 'Instance',
          name: 'Warehouse',
        },
      },
    },
  ],
};

local top5WarehouseCloudServicesCreditsUsedPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'snowflake_warehouse_used_cloud_service_credits{job=~"$job", instance=~"$instance"}',
      datasource=promDatasource,
      format='table',
      legendFormat='__auto'
    ),
  ],
  type: 'table',
  title: 'Top 5 warehouse cloud services credits used',
  description: 'The top 5 warehouses that have the highest services credit usages.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'thresholds',
      },
      custom: {
        align: 'center',
        displayMode: 'auto',
        inspect: false,
      },
      decimals: 2,
      mappings: [],
      unit: 'credits/hr',
    },
    overrides: [],
  },
  options: {
    footer: {
      fields: '',
      reducer: [
        'sum',
      ],
      show: false,
    },
    showHeader: true,
  },
  pluginVersion: '9.1.7',
  transformations: [
    {
      id: 'groupBy',
      options: {
        fields: {
          Value: {
            aggregations: [
              'last',
            ],
            operation: 'aggregate',
          },
          instance: {
            aggregations: [],
            operation: 'groupby',
          },
          name: {
            aggregations: [],
            operation: 'groupby',
          },
        },
      },
    },
    {
      id: 'sortBy',
      options: {
        fields: {},
        sort: [
          {
            desc: true,
            field: 'Value (last)',
          },
        ],
      },
    },
    {
      id: 'limit',
      options: {
        limitField: 5,
      },
    },
    {
      id: 'organize',
      options: {
        excludeByName: {},
        indexByName: {},
        renameByName: {
          'Value (last)': 'Credits',
          instance: 'Instance',
          name: 'Warehouse',
        },
      },
    },
  ],
};

local autoclusteringCreditsUsedPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'snowflake_auto_clustering_credits{job=~"$job", instance=~"$instance"}',
      datasource=promDatasource,
      legendFormat='{{database_name}} - {{schema_name}} - {{table_name}}'
    ),
  ],
  type: 'timeseries',
  title: 'Autoclustering credits used',
  description: 'Credits billed for automatic reclustering.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        barAlignment: 0,
        drawStyle: 'line',
        fillOpacity: 0,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineInterpolation: 'linear',
        lineWidth: 1,
        pointSize: 5,
        scaleDistribution: {
          type: 'linear',
        },
        showPoints: 'auto',
        spanNulls: 3600000,
        stacking: {
          group: 'A',
          mode: 'none',
        },
        thresholdsStyle: {
          mode: 'off',
        },
      },
      mappings: [],
      unit: 'credits/hr',
    },
    overrides: [],
  },
  interval: '15s',
  options: {
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    tooltip: {
      mode: 'single',
      sort: 'none',
    },
  },
};

local top5TableAutoclusteringCreditsUsedPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'snowflake_auto_clustering_credits{job=~"$job", instance=~"$instance"}',
      datasource=promDatasource,
      format='table',
      legendFormat='__auto'
    ),
  ],
  type: 'table',
  title: 'Top 5 table autoclustering credits used',
  description: 'The top 5 tables that have the highest autoclustering credit usages.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'thresholds',
      },
      custom: {
        align: 'center',
        displayMode: 'auto',
        inspect: false,
      },
      mappings: [],
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
        ],
      },
      unit: 'credits/hr',
    },
    overrides: [],
  },
  options: {
    footer: {
      fields: '',
      reducer: [
        'sum',
      ],
      show: false,
    },
    showHeader: true,
  },
  pluginVersion: '9.1.7',
  transformations: [
    {
      id: 'groupBy',
      options: {
        fields: {
          Value: {
            aggregations: [
              'last',
            ],
            operation: 'aggregate',
          },
          database_name: {
            aggregations: [],
            operation: 'groupby',
          },
          instance: {
            aggregations: [],
            operation: 'groupby',
          },
          schema_name: {
            aggregations: [],
            operation: 'groupby',
          },
          table_name: {
            aggregations: [],
            operation: 'groupby',
          },
        },
      },
    },
    {
      id: 'sortBy',
      options: {
        fields: {},
        sort: [
          {
            desc: true,
            field: 'Value (last)',
          },
        ],
      },
    },
    {
      id: 'limit',
      options: {
        limitField: 5,
      },
    },
    {
      id: 'organize',
      options: {
        excludeByName: {},
        indexByName: {
          'Value (last)': 4,
          database_name: 1,
          instance: 0,
          schema_name: 2,
          table_name: 3,
        },
        renameByName: {
          'Value (last)': 'Credits',
          database_name: 'Database',
          instance: 'Instance',
          schema_name: 'Schema',
          table_name: 'Table',
        },
      },
    },
  ],
};

local top5DatabaseAutoclusteringCreditsUsedPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (instance, job, database_name) (snowflake_auto_clustering_credits{job=~"$job", instance=~"$instance"})',
      datasource=promDatasource,
      format='table',
      legendFormat='__auto'
    ),
  ],
  type: 'table',
  title: 'Top 5 database autoclustering credits used',
  description: 'The top 5 databases that have the highest autoclustering credit usages.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'thresholds',
      },
      custom: {
        align: 'center',
        displayMode: 'auto',
        inspect: false,
      },
      mappings: [],
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
          {
            color: 'red',
            value: 80,
          },
        ],
      },
      unit: 'credits/hr',
    },
    overrides: [],
  },
  options: {
    footer: {
      fields: '',
      reducer: [
        'sum',
      ],
      show: false,
    },
    showHeader: true,
  },
  pluginVersion: '9.1.7',
  transformations: [
    {
      id: 'groupBy',
      options: {
        fields: {
          Value: {
            aggregations: [
              'last',
            ],
            operation: 'aggregate',
          },
          database_name: {
            aggregations: [],
            operation: 'groupby',
          },
          instance: {
            aggregations: [],
            operation: 'groupby',
          },
        },
      },
    },
    {
      id: 'sortBy',
      options: {
        fields: {},
        sort: [
          {
            desc: true,
            field: 'Value (last)',
          },
        ],
      },
    },
    {
      id: 'limit',
      options: {
        limitField: 5,
      },
    },
    {
      id: 'organize',
      options: {
        excludeByName: {},
        indexByName: {
          'Value (last)': 2,
          database_name: 1,
          instance: 0,
        },
        renameByName: {
          'Value (last)': 'Credits',
          database_name: 'Database',
          instance: 'Instance',
        },
      },
    },
  ],
};

{
  grafanaDashboards+:: {
    'snowflake-overview.json':
      dashboard.new(
        'Snowflake overview',
        time_from='%s' % $._config.dashboardPeriod,
        tags=($._config.dashboardTags),
        timezone='%s' % $._config.dashboardTimezone,
        refresh='%s' % $._config.dashboardRefresh,
        description='Overview of Snowflake traffic and billing.',
        uid=dashboardUid,
      )
      .addLink(grafana.link.dashboards(
        asDropdown=false,
        title='Other Snowflake dashboards',
        includeVars=true,
        keepTime=true,
        tags=($._config.dashboardTags),
      ))
      .addTemplates(
        [
          template.datasource(
            promDatasourceName,
            'prometheus',
            null,
            label='Data Source',
            refresh='load'
          ),
          template.new(
            'job',
            promDatasource,
            'label_values(snowflake_up{}, job)',
            label='Job',
            refresh=2,
            includeAll=true,
            multi=true,
            allValues='.+',
            sort=2
          ),
          template.new(
            'instance',
            promDatasource,
            'label_values(snowflake_up{}, instance)',
            label='instance',
            refresh=2,
            includeAll=true,
            multi=true,
            allValues='.*',
            sort=2
          ),
          template.new(
            'warehouse',
            promDatasource,
            'label_values(snowflake_warehouse_used_compute_credits{name!="CLOUD_SERVICES_ONLY"}, name)',
            label='Warehouse',
            refresh=2,
            includeAll=true,
            multi=true,
            allValues='.*',
            sort=2
          ),
        ]
      )
      .addPanels(
        [
          warehouseActivityPanel { gridPos: { h: 7, w: 12, x: 0, y: 0 } },
          accountStorageUsagePanel { gridPos: { h: 7, w: 12, x: 12, y: 0 } },
          loginAttemptsPanel { gridPos: { h: 7, w: 12, x: 0, y: 7 } },
          successfulLoginAttemptsPanel { gridPos: { h: 7, w: 6, x: 12, y: 7 } },
          failedLoginAttemptsPanel { gridPos: { h: 7, w: 6, x: 18, y: 7 } },
          billingRow { gridPos: { h: 1, w: 24, x: 0, y: 14 } },
          averageHourlyCreditsUsedPanel { gridPos: { h: 7, w: 12, x: 0, y: 15 } },
          autoclusteringCreditsUsedPanel { gridPos: { h: 7, w: 12, x: 12, y: 15 } },
          top5ServiceComputeCreditsUsedPanel { gridPos: { h: 7, w: 12, x: 0, y: 22 } },
          top5ServiceCloudServiceCreditsUsedPanel { gridPos: { h: 7, w: 12, x: 12, y: 22 } },
          top5WarehouseComputeCreditsUsedPanel { gridPos: { h: 7, w: 12, x: 0, y: 29 } },
          top5WarehouseCloudServicesCreditsUsedPanel { gridPos: { h: 7, w: 12, x: 12, y: 29 } },
          top5DatabaseAutoclusteringCreditsUsedPanel { gridPos: { h: 7, w: 12, x: 0, y: 36 } },
          top5TableAutoclusteringCreditsUsedPanel { gridPos: { h: 7, w: 12, x: 12, y: 36 } },
        ]
      ),
  },
}
