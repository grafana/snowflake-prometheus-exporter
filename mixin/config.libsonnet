{
  local this = self,
  filteringSelector: 'job="integrations/snowflake"',
  groupLabels: ['job'],
  uid: 'snowflake',
  instanceLabels: ['instance'],
  enableLokiLogs: false,
  ownershipLabels: ['database_name', 'schema_name'],

  // dashboard config
  dashboardTags: [this.uid + '-mixin'],
  dashboardNamePrefix: 'Snowflake',
  dashboardPeriod: 'now-8h',
  dashboardTimezone: 'default',
  dashboardRefresh: '30m',
  metricsSource: 'prometheus',

  // for alerts
  alertsWarningLoginFailures: '30',  // %
  alertsComputeCreditUsageLimit: '5',  // credits/hr
  alertsServiceCreditUsageLimit: '1',  // credits/hr

  signals+: {
    overview: (import './signals/overview.libsonnet')(this),
    ownership: (import './signals/ownership.libsonnet')(this),
  },
}
