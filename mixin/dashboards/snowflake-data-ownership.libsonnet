local g = (import 'grafana-builder/grafana.libsonnet');
local grafana = (import 'grafonnet/grafana.libsonnet');
local dashboard = grafana.dashboard;
local template = grafana.template;
local prometheus = grafana.prometheus;

local dashboardUid = 'snowflake-data-ownership';

local promDatasourceName = 'prometheus_datasource';

local promDatasource = {
  uid: '${%s}' % promDatasourceName,
};

local activeSchemaOwnedDataPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (instance, database_name, schema_name) (last_over_time(snowflake_table_active_bytes{job=~"$job", instance=~"$instance", database_name=~"$database", schema_name=~"$schema"}[24h]))',
      datasource=promDatasource,
      legendFormat='{{instance}} - {{database_name}} - {{schema_name}}'
    ),
  ],
  type: 'timeseries',
  title: 'Active schema owned data',
  description: 'Amount of active data owned by the selected schema.',
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

local timeTravelSchemaOwnedDataPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (instance, database_name, schema_name) (last_over_time(snowflake_table_time_travel_bytes{job=~"$job", instance=~"$instance", database_name=~"$database", schema_name=~"$schema"}[24h]))',
      datasource=promDatasource,
      legendFormat='{{instance}} - {{database_name}} - {{schema_name}}'
    ),
  ],
  type: 'timeseries',
  title: 'Time travel schema owned data',
  description: 'Amount of Time Travel data owned by the selected schema.',
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

local failsafeSchemaOwnedDataPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (instance, database_name, schema_name) (last_over_time(snowflake_table_failsafe_bytes{job=~"$job", instance=~"$instance", database_name=~"$database", schema_name=~"$schema"}[24h]))',
      datasource=promDatasource,
      legendFormat='{{instance}} - {{database_name}} - {{schema_name}}'
    ),
  ],
  type: 'timeseries',
  title: 'Fail-safe schema owned data',
  description: 'Amount of fail-safe data owned by the selected schema.',
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

local cloneSchemaOwnedDataPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (instance, database_name, schema_name) (last_over_time(snowflake_table_clone_bytes{job=~"$job", instance=~"$instance", database_name=~"$database", schema_name=~"$schema"}[24h]))',
      datasource=promDatasource,
      legendFormat='{{instance}} - {{database_name}} - {{schema_name}}'
    ),
  ],
  type: 'timeseries',
  title: 'Clone schema owned data',
  description: 'Amount of clone data owned by the selected schema.',
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

local top5LargestTablesPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'last_over_time(snowflake_table_active_bytes{job=~"$job", instance=~"$instance", database_name=~"$database", schema_name=~"$schema"}[24h])',
      datasource=promDatasource,
      format='table',
      legendFormat='__auto'
    ),
  ],
  type: 'table',
  title: 'Top 5 largest tables',
  description: 'The top 5 largest tables that belong to the selected schema.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'thresholds',
      },
      custom: {
        align: 'left',
        displayMode: 'auto',
        inspect: false,
      },
      mappings: [],
      unit: 'bytes',
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
          'Value (last)': 'Size',
          database_name: 'Database',
          instance: 'Instance',
          schema_name: 'Schema',
          table_name: 'Table',
        },
      },
    },
  ],
};

local deletedTablesPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'snowflake_table_deleted_tables{job=~"$job", instance=~"$instance"}',
      datasource=promDatasource,
      legendFormat='{{instance}}',
      format='time_series',
    ),
  ],
  type: 'stat',
  title: 'Deleted tables',
  description: 'The number of tables that have been purged from storage.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'fixed',
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
      unit: 'none',
    },
    overrides: [],
  },
  interval: '15s',
  options: {
    colorMode: 'value',
    graphMode: 'none',
    justifyMode: 'center',
    orientation: 'auto',
    percentChangeColorMode: 'standard',
    reduceOptions: {
      calcs: [
        'lastNotNull',
      ],
      fields: '',
      values: false,
    },
    showPercentChange: false,
    textMode: 'auto',
    wideLayout: true,
  },
  pluginVersion: '11.2.0-73830',
};

local tableDataRow = {
  datasource: promDatasource,
  targets: [],
  type: 'row',
  title: 'Table data',
  collapsed: false,
};

local activeTableOwnedDataPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (instance, database_name, schema_name, table_name) (last_over_time(snowflake_table_active_bytes{job=~"$job", instance=~"$instance", database_name=~"$database", schema_name=~"$schema", table_name=~"$table"}[24h]))',
      datasource=promDatasource,
      legendFormat='{{instance}} - {{database_name}} - {{schema_name}} - {{table_name}}'
    ),
  ],
  type: 'timeseries',
  title: 'Active table owned data',
  description: 'Amount of active data owned by the selected table.',
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

local timeTravelTableOwnedDataPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (instance, database_name, schema_name, table_name) (last_over_time(snowflake_table_time_travel_bytes{job=~"$job", instance=~"$instance", database_name=~"$database", schema_name=~"$schema", table_name=~"$table"}[24h]))',
      datasource=promDatasource,
      legendFormat='{{instance}} - {{database_name}} - {{schema_name}} - {{table_name}}'
    ),
  ],
  type: 'timeseries',
  title: 'Time travel table owned data',
  description: 'Amount of Time Travel data owned by the selected table.',
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

local failsafeTableOwnedDataPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (instance, database_name, schema_name, table_name) (last_over_time(snowflake_table_failsafe_bytes{job=~"$job", instance=~"$instance", database_name=~"$database", schema_name=~"$schema", table_name=~"$table"}[24h]))',
      datasource=promDatasource,
      legendFormat='{{instance}} - {{database_name}} - {{schema_name}} - {{table_name}}'
    ),
  ],
  type: 'timeseries',
  title: 'Fail-safe table owned data',
  description: 'Amount of fail-safe data owned by the selected table.',
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

local cloneTableOwnedDataPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'sum by (instance, database_name, schema_name, table_name) (last_over_time(snowflake_table_clone_bytes{job=~"$job", instance=~"$instance", database_name=~"$database", schema_name=~"$schema", table_name=~"$table"}[24h]))',
      datasource=promDatasource,
      legendFormat='{{instance}} - {{database_name}} - {{schema_name}} - {{table_name}}'
    ),
  ],
  type: 'timeseries',
  title: 'Clone table owned data',
  description: 'Amount of clone data owned by the selected table.',
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

{
  grafanaDashboards+:: {
    'snowflake-data-ownership.json':
      dashboard.new(
        'Snowflake data ownership',
        time_from='%s' % $._config.dashboardPeriod,
        tags=($._config.dashboardTags),
        timezone='%s' % $._config.dashboardTimezone,
        refresh='%s' % $._config.dashboardRefresh,
        description='A dashboard displaying metrics relating to data ownership.',
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
            'label_values(snowflake_up{job=~"$job"}, instance)',
            label='Instance',
            refresh=2,
            includeAll=true,
            multi=true,
            allValues='.+',
            sort=2
          ),
          template.new(
            'database',
            promDatasource,
            'label_values(snowflake_table_active_bytes{job=~"$job", instance=~"$instance"}, database_name)',
            label='Database',
            refresh=2,
            includeAll=true,
            multi=true,
            allValues='.+',
            sort=2
          ),
          template.new(
            'schema',
            promDatasource,
            'label_values(snowflake_table_active_bytes{job=~"$job", instance=~"$instance", database_name=~"$database"}, schema_name)',
            label='Schema',
            refresh=2,
            includeAll=true,
            multi=true,
            allValues='.+',
            sort=2
          ),
          template.new(
            'table',
            promDatasource,
            'label_values(snowflake_table_active_bytes{job=~"$job", instance=~"$instance", database_name=~"$database",  schema_name=~"$schema"}, table_name)',
            label='Table',
            refresh=2,
            includeAll=true,
            multi=true,
            allValues='.+',
            sort=2
          ),
        ]
      )
      .addPanels(
        [
          activeSchemaOwnedDataPanel { gridPos: { h: 8, w: 6, x: 0, y: 0 } },
          failsafeSchemaOwnedDataPanel { gridPos: { h: 8, w: 6, x: 6, y: 0 } },
          cloneSchemaOwnedDataPanel { gridPos: { h: 8, w: 6, x: 12, y: 0 } },
          timeTravelSchemaOwnedDataPanel { gridPos: { h: 8, w: 6, x: 18, y: 0 } },
          top5LargestTablesPanel { gridPos: { h: 7, w: 18, x: 0, y: 8 } },
          deletedTablesPanel { gridPos: { h: 7, w: 6, x: 18, y: 8 } },
          tableDataRow { gridPos: { h: 1, w: 24, x: 0, y: 15 } },
          activeTableOwnedDataPanel { gridPos: { h: 8, w: 12, x: 0, y: 16 } },
          failsafeTableOwnedDataPanel { gridPos: { h: 8, w: 12, x: 12, y: 16 } },
          timeTravelTableOwnedDataPanel { gridPos: { h: 8, w: 12, x: 0, y: 24 } },
          cloneTableOwnedDataPanel { gridPos: { h: 8, w: 12, x: 12, y: 24 } },
        ]
      ),

  },
}
