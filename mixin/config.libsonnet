{
  _config+:: {
    dashboardTags: ['snowflake-mixin'],
    dashboardPeriod: 'now-8h',
    dashboardTimezone: 'default',
    dashboardRefresh: '30m',

    // for alerts
    alertsWarningLoginFailures: '30',  // %
    alertsComputeCreditUsageLimit: '5',  // credits/hr
    alertsServiceCreditUsageLimit: '1',  // credits/hr
  },
}
