local g = import './g.libsonnet';
local commonlib = import 'common-lib/common/main.libsonnet';

{
  local root = self,
  new(this)::
    local prefix = this.config.dashboardNamePrefix;
    local links = this.grafana.links;
    local tags = this.config.dashboardTags;
    local uid = g.util.string.slugify(this.config.uid);
    local vars = this.grafana.variables;
    local annotations = this.grafana.annotations;
    local refresh = this.config.dashboardRefresh;
    local period = this.config.dashboardPeriod;
    local timezone = this.config.dashboardTimezone;
    {
      'snowflake-overview.json':
        g.dashboard.new(prefix + ' overview')
        + g.dashboard.withPanels(
          g.util.panel.resolveCollapsedFlagOnRows(
            g.util.grid.wrapPanels(
              [
                this.grafana.rows.overview,
                this.grafana.rows.billing,
              ]
            )
          )
        ) + root.applyCommon(
          vars.multiInstance + [
          ],
          uid + '_overview',
          tags,
          links { snowflakeOverview:: {} },
          annotations,
          timezone,
          refresh,
          period,
        ),

      'snowflake-data-ownership.json':
        g.dashboard.new(prefix + ' data ownership')
        + g.dashboard.withPanels(
          g.util.panel.resolveCollapsedFlagOnRows(
            g.util.grid.wrapPanels(
              [
                this.grafana.rows.dataOwnership,
                this.grafana.rows.tableData,
              ]
            )
          )
        ) + root.applyCommon(
          vars.multiInstance + [
            g.dashboard.variable.query.new(
              'database_name',
            )
            + g.dashboard.variable.custom.selectionOptions.withMulti(true)
            + g.dashboard.variable.custom.selectionOptions.withIncludeAll(true)
            + g.dashboard.variable.query.queryTypes.withLabelValues(label='database_name', metric='snowflake_table_active_bytes{%(queriesSelector)s}' % vars)
            + g.dashboard.variable.query.withDatasourceFromVariable(vars.datasources.prometheus),

            g.dashboard.variable.query.new(
              'schema_name',
            )
            + g.dashboard.variable.custom.selectionOptions.withMulti(true)
            + g.dashboard.variable.custom.selectionOptions.withIncludeAll(true)
            + g.dashboard.variable.query.queryTypes.withLabelValues(label='schema_name', metric='snowflake_table_active_bytes{%(queriesSelector)s, database_name=~"$database_name"}' % vars)
            + g.dashboard.variable.query.withDatasourceFromVariable(vars.datasources.prometheus),

            g.dashboard.variable.query.new(
              'table_name',
            )
            + g.dashboard.variable.custom.selectionOptions.withMulti(true)
            + g.dashboard.variable.custom.selectionOptions.withIncludeAll(true)
            + g.dashboard.variable.query.queryTypes.withLabelValues(label='table_name', metric='snowflake_table_active_bytes{%(queriesSelector)s, database_name=~"$database_name", schema_name=~"$schema_name"}' % vars)
            + g.dashboard.variable.query.withDatasourceFromVariable(vars.datasources.prometheus),
          ],
          uid + '_data_ownership',
          tags,
          links { snowflakeDataOwnership:: {} },
          annotations,
          timezone,
          refresh,
          period,
        ),
    },
  applyCommon(vars, uid, tags, links, annotations, timezone, refresh, period):
    g.dashboard.withTags(tags)
    + g.dashboard.withUid(uid)
    + g.dashboard.withLinks(std.objectValues(links))
    + g.dashboard.withTimezone(timezone)
    + g.dashboard.withRefresh(refresh)
    + g.dashboard.time.withFrom(period)
    + g.dashboard.withVariables(vars)
    + g.dashboard.withAnnotations(std.objectValues(annotations)),

}
