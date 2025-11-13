local snowflakelib = import './main.libsonnet';
local config = (import './config.libsonnet');
local util = import 'grafana-cloud-integration-utils/util.libsonnet';

local snowflake =
  snowflakelib.new()
  + snowflakelib.withConfigMixin(
    {
      filteringSelector: config.filteringSelector,
      uid: config.uid,
      enableLokiLogs: false,
    }
  );

local optional_labels = {
  warehouse+: {
    label: 'Warehouse',
    allValue: '.*',
  },
  instance+: {
    label: 'Exporter instance',
  }
};

{
  grafanaDashboards+:: {
    [fname]:
      local dashboard = snowflake.grafana.dashboards[fname];
      dashboard + util.patch_variables(dashboard, optional_labels)

    for fname in std.objectFields(snowflake.grafana.dashboards)
  },

  prometheusAlerts+:: snowflake.prometheus.alerts,
  prometheusRules+:: snowflake.prometheus.recordingRules,
}
