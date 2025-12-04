local g = import './g.libsonnet';

{
  local link = g.dashboard.link,
  new(this):
    {
      snowflakeOverview:
        link.link.new('Snowflake overview', '/d/' + this.grafana.dashboards['snowflake-overview.json'].uid)
        + link.link.options.withKeepTime(true),
      snowflakeDataOwnership:
        link.link.new('Snowflake data ownership', '/d/' + this.grafana.dashboards['snowflake-data-ownership.json'].uid)
        + link.link.options.withKeepTime(true),

      otherDashboards:
        link.dashboards.new('All dashboards', this.config.dashboardTags)
        + link.dashboards.options.withIncludeVars(true)
        + link.dashboards.options.withKeepTime(true)
        + link.dashboards.options.withAsDropdown(true),
    },
}
