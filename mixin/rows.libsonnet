local g = import './g.libsonnet';

{
  new(this):
    {
      local panels = this.grafana.panels,

      overview:
        g.panel.row.new('Overview')
        + g.panel.row.withCollapsed(false)
        + g.panel.row.withPanels(
          [
            panels.overviewWarehouseActivity { gridPos: { w: 12 } },
            panels.accountStorageUsage { gridPos: { w: 12 } },
            panels.loginAttempts { gridPos: { w: 12 } },
            panels.successfulLoginAttempts { gridPos: { w: 6 } },
            panels.failedLoginAttempts { gridPos: { w: 6 } },
          ]
        ),

      billing:
        g.panel.row.new('Billing')
        + g.panel.row.withPanels(
          [
            panels.averageHourlyCreditsUsed { gridPos: { w: 12 } },
            panels.autoclusteringCreditsUsed { gridPos: { w: 12 } },
            panels.top5ServiceComputeCreditsUsed { gridPos: { w: 12 } },
            panels.top5ServiceCloudServiceCreditsUsed { gridPos: { w: 12 } },
            panels.top5WarehouseComputeCreditsUsed { gridPos: { w: 12 } },
            panels.top5WarehouseCloudServicesCreditsUsed { gridPos: { w: 12 } },
            panels.top5DatabaseAutoclusteringCreditsUsed { gridPos: { w: 12 } },
            panels.top5TableAutoclusteringCreditsUsed { gridPos: { w: 12 } },
          ]
        ),

      dataOwnership:
        g.panel.row.new('Data ownership')
        + g.panel.row.withPanels(
          [
            panels.activeSchemaOwnedData { gridPos: { w: 6 } },
            panels.failsafeSchemaOwnedData { gridPos: { w: 6 } },
            panels.cloneSchemaOwnedData { gridPos: { w: 6 } },
            panels.timeTravelSchemaOwnedData { gridPos: { w: 6 } },
            panels.top5LargestTables { gridPos: { w: 18 } },
            panels.deletedTables { gridPos: { w: 6 } },
          ]
        ),

      tableData:
        g.panel.row.new('Table data')
        + g.panel.row.withPanels(
          [
            panels.activeTableOwnedData { gridPos: { w: 12 } },
            panels.failsafeTableOwnedData { gridPos: { w: 12 } },
            panels.timeTravelTableOwnedData { gridPos: { w: 12 } },
            panels.cloneTableOwnedData { gridPos: { w: 12 } },
          ]
        ),
    },
}
