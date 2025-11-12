local g = import './g.libsonnet';
local commonlib = import 'common-lib/common/main.libsonnet';

{
  new(this)::
    {
      local signals = this.signals,

      overviewWarehouseActivity:
        commonlib.panels.generic.timeSeries.base.new(
          'Warehouse activity',
          targets=[
            signals.overview.warehouseActivityExecutedQueries.asTarget(),
            signals.overview.warehouseActivityOverloadedQueueLoad.asTarget(),
            signals.overview.warehouseActivityProvisioningQueueLoad.asTarget(),
            signals.overview.warehouseActivityBlockedQueryLoad.asTarget(),
          ],
        )
        + g.panel.timeSeries.panelOptions.withDescription('Warehouse query activity for the warehouse selected by the Warehouse selector.')
        + g.panel.timeSeries.standardOptions.withUnit('percentunit'),

      accountStorageUsage:
        commonlib.panels.generic.timeSeries.base.new(
          'Account storage usage',
          targets=[
            signals.overview.accountStorageUsage.asTarget(),
            signals.overview.accountStageUsage.asTarget(),
            signals.overview.accountFailsafeUsage.asTarget(),
          ],
        )
        + g.panel.timeSeries.panelOptions.withDescription('Data storage used for the account.')
        + g.panel.timeSeries.standardOptions.withUnit('bytes'),

      loginAttempts:
        commonlib.panels.generic.timeSeries.base.new(
          'Login attempts',
          targets=[
            signals.overview.loginAttemptsTotal.asTarget(),
            signals.overview.loginAttemptsFailed.asTarget(),
            signals.overview.loginAttemptsSuccessful.asTarget(),
          ],
        )
        + g.panel.timeSeries.panelOptions.withDescription('Login attempt rate over the last 24 hours.')
        + g.panel.timeSeries.standardOptions.withUnit('logins/hr'),

      successfulLoginAttempts:
        g.panel.gauge.new(
          'Successful login attempts',
        )
        + g.panel.gauge.queryOptions.withTargets([signals.overview.successfulLoginAttempts.asTarget()])
        + g.panel.gauge.panelOptions.withDescription('Percentage of total login attempts that were successful.')
        + g.panel.gauge.standardOptions.withUnit('percentunit')
        + g.panel.gauge.standardOptions.withMin(0)
        + g.panel.gauge.standardOptions.withMax(1)
        + g.panel.gauge.standardOptions.thresholds.withSteps([
          g.panel.gauge.thresholdStep.withColor('red') + g.panel.gauge.thresholdStep.withValue(0),
          g.panel.gauge.thresholdStep.withColor('yellow') + g.panel.gauge.thresholdStep.withValue(0.6),
          g.panel.gauge.thresholdStep.withColor('green') + g.panel.gauge.thresholdStep.withValue(0.8),
        ])
        + g.panel.gauge.options.withReduceOptions({
          calcs: ['lastNotNull'],
          fields: '',
          limit: 1,
          values: false,
        })
        + g.panel.gauge.options.withShowThresholdLabels(false)
        + g.panel.gauge.options.withShowThresholdMarkers(false),

      failedLoginAttempts:
        g.panel.gauge.new(
          'Failed login attempts',
        )
        + g.panel.gauge.queryOptions.withTargets([signals.overview.failedLoginAttempts.asTarget()])
        + g.panel.gauge.panelOptions.withDescription('Percentage of total login attempts that failed.')
        + g.panel.gauge.standardOptions.withUnit('percentunit')
        + g.panel.gauge.standardOptions.withMin(0)
        + g.panel.gauge.standardOptions.withMax(1)
        + g.panel.gauge.standardOptions.thresholds.withSteps([
          g.panel.gauge.thresholdStep.withColor('green'),
          g.panel.gauge.thresholdStep.withColor('#EAB839') + g.panel.gauge.thresholdStep.withValue(0.2),
          g.panel.gauge.thresholdStep.withColor('red') + g.panel.gauge.thresholdStep.withValue(0.4),
        ])
        + g.panel.gauge.options.withReduceOptions({
          calcs: ['lastNotNull'],
          fields: '',
          values: false,
        })
        + g.panel.gauge.options.withShowThresholdLabels(false)
        + g.panel.gauge.options.withShowThresholdMarkers(false),

      // Billing panels
      computeBillingUsage:
        commonlib.panels.generic.timeSeries.base.new(
          'Billing usage',
          targets=[
            signals.overview.computeCreditUsagePercentage.asTarget(),
          ],
        )
        + g.panel.timeSeries.panelOptions.withDescription('Billing usage for the account.')
        + g.panel.timeSeries.standardOptions.withUnit('percent')
        + g.panel.timeSeries.standardOptions.thresholds.withSteps([
          g.panel.timeSeries.thresholdStep.withColor('transparent')
          + g.panel.timeSeries.thresholdStep.withValue(null),
          g.panel.timeSeries.thresholdStep.withColor('orange')
          + g.panel.timeSeries.thresholdStep.withValue(80),
          g.panel.timeSeries.thresholdStep.withColor('red')
          + g.panel.timeSeries.thresholdStep.withValue(100),
        ])
        + g.panel.timeSeries.fieldConfig.defaults.custom.withThresholdsStyle('area'),

      cloudServicesBillingUsage:
        commonlib.panels.generic.timeSeries.base.new(
          'Cloud services billing usage',
          targets=[
            signals.overview.cloudServicesCreditUsagePercentage.asTarget(),
          ],
        )
        + g.panel.timeSeries.panelOptions.withDescription('Cloud services billing usage for the account.')
        + g.panel.timeSeries.standardOptions.withUnit('percent')
        + g.panel.timeSeries.standardOptions.thresholds.withSteps([
          g.panel.timeSeries.thresholdStep.withColor('transparent')
          + g.panel.timeSeries.thresholdStep.withValue(null),
          g.panel.timeSeries.thresholdStep.withColor('orange')
          + g.panel.timeSeries.thresholdStep.withValue(1),
          g.panel.timeSeries.thresholdStep.withColor('red')
          + g.panel.timeSeries.thresholdStep.withValue(100),
        ])
        + g.panel.timeSeries.fieldConfig.defaults.custom.withThresholdsStyle('area'),

      averageHourlyCreditsUsed:
        commonlib.panels.generic.timeSeries.base.new(
          'Average hourly credits used',
          targets=[
            signals.overview.usedComputeCredits.asTarget(),
            signals.overview.usedCloudServicesCredits.asTarget(),
          ],
        )
        + g.panel.timeSeries.options.legend.withAsTable(true)
        + g.panel.timeSeries.options.legend.withPlacement('right')
        + g.panel.timeSeries.panelOptions.withDescription('Number of billing credits used by the account.')
        + g.panel.timeSeries.fieldConfig.defaults.custom.withAxisLabel('credits/hr')
        + g.panel.timeSeries.standardOptions.withUnit('none'),

      autoclusteringCreditsUsed:
        commonlib.panels.generic.timeSeries.base.new(
          'Autoclustering credits used',
          targets=[
            signals.overview.autoclusteringCreditsUsed.asTarget(),
          ],
        )
        + g.panel.timeSeries.options.legend.withAsTable(true)
        + g.panel.timeSeries.options.legend.withPlacement('right')
        + g.panel.timeSeries.panelOptions.withDescription('Credits billed for automatic reclustering.')
        + g.panel.timeSeries.fieldConfig.defaults.custom.withAxisLabel('credits/hr')
        + g.panel.timeSeries.standardOptions.withUnit('none'),

      top5ServiceComputeCreditsUsed:
        commonlib.panels.generic.table.base.new(
          'Top 5 service compute credits used',
          targets=[
            signals.overview.serviceComputeCreditsUsed.asTableTarget(),
          ],
        )
        + g.panel.table.panelOptions.withDescription('The top 5 services that have the highest compute credit usages.')
        + g.panel.table.standardOptions.withOverridesMixin([
          g.panel.table.fieldOverride.byName.new('Credits')
          + g.panel.table.fieldOverride.byName.withProperty('unit', 'credits/hr')
          + g.panel.table.fieldOverride.byName.withProperty('decimals', 2),
        ])
        + g.panel.table.options.withShowHeader(true)
        + g.panel.table.queryOptions.withTransformations([
          {
            id: 'groupBy',
            options: {
              fields: {
                Value: {
                  aggregations: ['last'],
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
        ]),

      top5ServiceCloudServiceCreditsUsed:
        commonlib.panels.generic.table.base.new(
          'Top 5 service cloud service credits used',
          targets=[
            signals.overview.serviceCloudServicesCreditsUsed.asTableTarget(),
          ],
        )
        + g.panel.table.panelOptions.withDescription('The top 5 services that have the highest compute credit usages.')
        + g.panel.table.standardOptions.withOverridesMixin([
          g.panel.table.fieldOverride.byName.new('Credits')
          + g.panel.table.fieldOverride.byName.withProperty('unit', 'credits/hr')
          + g.panel.table.fieldOverride.byName.withProperty('decimals', 2),
        ])
        + g.panel.table.options.withShowHeader(true)
        + g.panel.table.queryOptions.withTransformations([
          {
            id: 'groupBy',
            options: {
              fields: {
                Value: {
                  aggregations: ['last'],
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
        ]),

      top5WarehouseComputeCreditsUsed:
        commonlib.panels.generic.table.base.new(
          'Top 5 warehouse compute credits used',
          targets=[
            signals.overview.warehouseComputeCreditsUsed.asTableTarget(),
          ],
        )
        + g.panel.table.panelOptions.withDescription('The top 5 warehouses that have the highest compute credit usages.')
        + g.panel.table.standardOptions.withOverridesMixin([
          g.panel.table.fieldOverride.byName.new('Credits')
          + g.panel.table.fieldOverride.byName.withProperty('unit', 'credits/hr'),
        ])
        + g.panel.table.options.withShowHeader(true)
        + g.panel.table.queryOptions.withTransformations([
          {
            id: 'groupBy',
            options: {
              fields: {
                Value: {
                  aggregations: ['last'],
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
        ]),

      top5WarehouseCloudServicesCreditsUsed:
        commonlib.panels.generic.table.base.new(
          'Top 5 warehouse cloud services credits used',
          targets=[
            signals.overview.warehouseCloudServicesCreditsUsed.asTableTarget(),
          ],
        )
        + g.panel.table.panelOptions.withDescription('The top 5 warehouses that have the highest services credit usages.')
        + g.panel.table.standardOptions.withOverridesMixin([
          g.panel.table.fieldOverride.byName.new('Credits')
          + g.panel.table.fieldOverride.byName.withProperty('unit', 'credits/hr')
          + g.panel.table.fieldOverride.byName.withProperty('decimals', 2),
        ])
        + g.panel.table.options.withShowHeader(true)
        + g.panel.table.queryOptions.withTransformations([
          {
            id: 'groupBy',
            options: {
              fields: {
                Value: {
                  aggregations: ['last'],
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
        ]),

      top5TableAutoclusteringCreditsUsed:
        commonlib.panels.generic.table.base.new(
          'Top 5 table autoclustering credits used',
          targets=[
            signals.overview.tableAutoclusteringCreditsUsed.asTableTarget(),
          ],
        )
        + g.panel.table.panelOptions.withDescription('The top 5 tables that have the highest autoclustering credit usages.')
        + g.panel.table.standardOptions.withOverridesMixin([
          g.panel.table.fieldOverride.byName.new('Credits')
          + g.panel.table.fieldOverride.byName.withProperty('unit', 'credits/hr'),
        ])
        + g.panel.table.options.withShowHeader(true)
        + g.panel.table.queryOptions.withTransformations([
          {
            id: 'groupBy',
            options: {
              fields: {
                Value: {
                  aggregations: ['last'],
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
        ]),

      top5DatabaseAutoclusteringCreditsUsed:
        commonlib.panels.generic.table.base.new(
          'Top 5 database autoclustering credits used',
          targets=[
            signals.overview.databaseAutoclusteringCreditsUsed.asTableTarget(),
          ],
        )
        + g.panel.table.panelOptions.withDescription('The top 5 databases that have the highest autoclustering credit usages.')
        + g.panel.table.standardOptions.withOverridesMixin([
          g.panel.table.fieldOverride.byName.new('Credits')
          + g.panel.table.fieldOverride.byName.withProperty('unit', 'credits/hr'),
        ])
        + g.panel.table.options.withShowHeader(true)
        + g.panel.table.queryOptions.withTransformations([
          {
            id: 'groupBy',
            options: {
              fields: {
                Value: {
                  aggregations: ['last'],
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
        ]),

      // Ownership panels - Schema data
      activeSchemaOwnedData:
        commonlib.panels.generic.timeSeries.base.new(
          'Active schema owned data',
          targets=[
            signals.ownership.activeSchemaOwnedData.asTarget(),
          ],
        )
        + g.panel.timeSeries.options.legend.withAsTable(true)
        + g.panel.timeSeries.options.legend.withPlacement('right')
        + g.panel.timeSeries.panelOptions.withDescription('Amount of active data owned by the selected schema.')
        + g.panel.timeSeries.standardOptions.withUnit('bytes'),

      timeTravelSchemaOwnedData:
        commonlib.panels.generic.timeSeries.base.new(
          'Time travel schema owned data',
          targets=[
            signals.ownership.timeTravelSchemaOwnedData.asTarget(),
          ],
        )
        + g.panel.timeSeries.options.legend.withAsTable(true)
        + g.panel.timeSeries.options.legend.withPlacement('right')
        + g.panel.timeSeries.panelOptions.withDescription('Amount of Time Travel data owned by the selected schema.')
        + g.panel.timeSeries.standardOptions.withUnit('bytes'),

      failsafeSchemaOwnedData:
        commonlib.panels.generic.timeSeries.base.new(
          'Fail-safe schema owned data',
          targets=[
            signals.ownership.failsafeSchemaOwnedData.asTarget(),
          ],
        )
        + g.panel.timeSeries.options.legend.withAsTable(true)
        + g.panel.timeSeries.options.legend.withPlacement('right')
        + g.panel.timeSeries.panelOptions.withDescription('Amount of fail-safe data owned by the selected schema.')
        + g.panel.timeSeries.standardOptions.withUnit('bytes'),

      cloneSchemaOwnedData:
        commonlib.panels.generic.timeSeries.base.new(
          'Clone schema owned data',
          targets=[
            signals.ownership.cloneSchemaOwnedData.asTarget(),
          ],
        )
        + g.panel.timeSeries.options.legend.withAsTable(true)
        + g.panel.timeSeries.options.legend.withPlacement('right')
        + g.panel.timeSeries.panelOptions.withDescription('Amount of clone data owned by the selected schema.')
        + g.panel.timeSeries.standardOptions.withUnit('bytes'),

      top5LargestTables:
        commonlib.panels.generic.table.base.new(
          'Top 5 largest tables',
          targets=[
            signals.ownership.top5LargestTables.asTableTarget(),
          ],
        )
        + g.panel.table.panelOptions.withDescription('The top 5 largest tables that belong to the selected schema.')
        + g.panel.table.standardOptions.withOverridesMixin([
          g.panel.table.fieldOverride.byName.new('Size')
          + g.panel.table.fieldOverride.byName.withProperty('unit', 'bytes'),
        ])
        + g.panel.table.options.withShowHeader(true)
        + g.panel.table.queryOptions.withTransformations([
          {
            id: 'groupBy',
            options: {
              fields: {
                Value: {
                  aggregations: ['last'],
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
        ]),

      deletedTables:
        commonlib.panels.generic.stat.base.new(
          'Deleted tables',
          targets=[
            signals.ownership.deletedTables.asTarget(),
          ],
        )
        + g.panel.stat.panelOptions.withDescription('The number of tables that have been purged from storage.')
        + g.panel.stat.standardOptions.withUnit('none'),

      // Ownership panels - Table data
      activeTableOwnedData:
        commonlib.panels.generic.timeSeries.base.new(
          'Active table owned data',
          targets=[
            signals.ownership.activeTableOwnedData.asTarget(),
          ],
        )
        + g.panel.timeSeries.options.legend.withAsTable(true)
        + g.panel.timeSeries.options.legend.withPlacement('right')
        + g.panel.timeSeries.panelOptions.withDescription('Amount of active data owned by the selected table.')
        + g.panel.timeSeries.standardOptions.withUnit('bytes'),

      timeTravelTableOwnedData:
        commonlib.panels.generic.timeSeries.base.new(
          'Time travel table owned data',
          targets=[
            signals.ownership.timeTravelTableOwnedData.asTarget(),
          ],
        )
        + g.panel.timeSeries.options.legend.withAsTable(true)
        + g.panel.timeSeries.options.legend.withPlacement('right')
        + g.panel.timeSeries.panelOptions.withDescription('Amount of Time Travel data owned by the selected table.')
        + g.panel.timeSeries.standardOptions.withUnit('bytes'),

      failsafeTableOwnedData:
        commonlib.panels.generic.timeSeries.base.new(
          'Fail-safe table owned data',
          targets=[
            signals.ownership.failsafeTableOwnedData.asTarget(),
          ],
        )
        + g.panel.timeSeries.options.legend.withAsTable(true)
        + g.panel.timeSeries.options.legend.withPlacement('right')
        + g.panel.timeSeries.panelOptions.withDescription('Amount of fail-safe data owned by the selected table.')
        + g.panel.timeSeries.standardOptions.withUnit('bytes'),

      cloneTableOwnedData:
        commonlib.panels.generic.timeSeries.base.new(
          'Clone table owned data',
          targets=[
            signals.ownership.cloneTableOwnedData.asTarget(),
          ],
        )
        + g.panel.timeSeries.options.legend.withAsTable(true)
        + g.panel.timeSeries.options.legend.withPlacement('right')
        + g.panel.timeSeries.panelOptions.withDescription('Amount of clone data owned by the selected table.')
        + g.panel.timeSeries.standardOptions.withUnit('bytes'),
    },
}
