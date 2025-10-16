// Copyright  Grafana Labs
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package collector

import (
	"database/sql"
	"fmt"
	"sync"

	"github.com/go-kit/log"
	"github.com/go-kit/log/level"
	"github.com/prometheus/client_golang/prometheus"
	_ "github.com/snowflakedb/gosnowflake" // Import the snowflake DB driver
)

const (
	namespace = "snowflake"

	labelName          = "name"
	labelID            = "id"
	labelDatabaseID    = "database_id"
	labelDatabaseName  = "database_name"
	labelServiceType   = "service_type"
	labelService       = "service"
	labelClientType    = "client_type"
	labelClientVersion = "client_version"
	labelTableName     = "table_name"
	labelTableID       = "table_id"
	labelSchemaName    = "schema_name"
	labelSchemaID      = "schema_id"
	labelSize          = "size"
)

// openSnowflakeDatabase opens a connection to a Snowflake database using the given connection string.
func openSnowflakeDatabase(connStr string) (*sql.DB, error) {
	return sql.Open("snowflake", connStr)
}

// Collector is a prometheus.Collector that retrieves metrics for a Snowflake account.
type Collector struct {
	config *Config
	logger log.Logger
	// For mocking
	openDatabase func(string) (*sql.DB, error)

	storageBytes                      *prometheus.Desc
	stageBytes                        *prometheus.Desc
	failsafeBytes                     *prometheus.Desc
	databaseBytes                     *prometheus.Desc
	databaseFailsafeBytes             *prometheus.Desc
	usedComputeCredits                *prometheus.Desc
	usedCloudServicesCredits          *prometheus.Desc
	warehouseUsedComputeCredits       *prometheus.Desc
	warehouseUsedCloudServicesCredits *prometheus.Desc
	logins                            *prometheus.Desc
	successfulLogins                  *prometheus.Desc
	failedLogins                      *prometheus.Desc
	warehouseExecutedQueryLoad        *prometheus.Desc
	warehouseOverloadedQueueLoad      *prometheus.Desc
	warehouseProvisioningQueueLoad    *prometheus.Desc
	warehouseBlockedQueryLoad         *prometheus.Desc
	autoClusteringCredits             *prometheus.Desc
	autoClusteringBytes               *prometheus.Desc
	autoClusteringRows                *prometheus.Desc
	tableActiveBytes                  *prometheus.Desc
	tableTimeTravelBytes              *prometheus.Desc
	tableFailsafeBytes                *prometheus.Desc
	tableCloneBytes                   *prometheus.Desc
	tableDeletedTables                *prometheus.Desc
	replicationUsedCredits            *prometheus.Desc
	replicationTransferredBytes       *prometheus.Desc
	up                                *prometheus.Desc
}

// NewCollector creates a new collector from a given config.
// The config is assumed to be valid.
func NewCollector(logger log.Logger, c *Config) *Collector {
	return &Collector{
		config:       c,
		logger:       logger,
		openDatabase: openSnowflakeDatabase,
		storageBytes: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "", "storage_bytes"),
			"Number of bytes of table storage used, including bytes for data currently in Time Travel.",
			nil,
			nil,
		),
		stageBytes: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "", "stage_bytes"),
			"Number of bytes of stage storage used by files in all internal stages (named, table, and user).",
			nil,
			nil,
		),
		failsafeBytes: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "", "failsafe_bytes"),
			"Number of bytes of data in Fail-safe.",
			nil,
			nil,
		),
		databaseBytes: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "database", "bytes"),
			"Average number of bytes of database storage used, including data in Time Travel.",
			[]string{labelName, labelID},
			nil,
		),
		databaseFailsafeBytes: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "database", "failsafe_bytes"),
			"Average number of bytes of Fail-safe storage used.",
			[]string{labelName, labelID},
			nil,
		),
		usedComputeCredits: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "", "used_compute_credits"),
			"Average overall credits billed per hour for virtual warehouses over the last 24 hours.",
			[]string{labelServiceType, labelService},
			nil,
		),
		usedCloudServicesCredits: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "", "used_cloud_services_credits"),
			"Average overall credits billed per hour for cloud services over the last 24 hours.",
			[]string{labelServiceType, labelService},
			nil,
		),
		warehouseUsedComputeCredits: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "warehouse", "used_compute_credits"),
			"Average overall credits billed per hour for the warehouse over the last 24 hours.",
			[]string{labelName, labelID},
			nil,
		),
		warehouseUsedCloudServicesCredits: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "warehouse", "used_cloud_service_credits"),
			"Average overall credits billed per hour for cloud services for the warehouse over the last 24 hours.",
			[]string{labelName, labelID},
			nil,
		),
		logins: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "", "login_rate"),
			"Rate of logins per-hour over the last 24 hours.",
			[]string{labelClientType, labelClientVersion},
			nil,
		),
		successfulLogins: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "", "successful_login_rate"),
			"Rate of successful logins per-hour over the last 24 hours.",
			[]string{labelClientType, labelClientVersion},
			nil,
		),
		failedLogins: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "", "failed_login_rate"),
			"Rate of failed logins per-hour over the last 24 hours.",
			[]string{labelClientType, labelClientVersion},
			nil,
		),
		warehouseExecutedQueryLoad: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "warehouse", "executed_queries"),
			"Average query load for queries executed over the last 24 hours.",
			[]string{labelName, labelID},
			nil,
		),
		warehouseOverloadedQueueLoad: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "warehouse", "overloaded_queue_size"),
			"Average load value for queries queued because the warehouse was being overloaded over the last 24 hours.",
			[]string{labelName, labelID},
			nil,
		),
		warehouseProvisioningQueueLoad: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "warehouse", "provisioning_queue_size"),
			"Average load value for queries queued because the warehouse was being provisioned over the last 24 hours.",
			[]string{labelName, labelID},
			nil,
		),
		warehouseBlockedQueryLoad: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "warehouse", "blocked_queries"),
			"Average load value for queries blocked by a transaction lock over the last 24 hours.",
			[]string{labelName, labelID},
			nil,
		),
		autoClusteringCredits: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "auto_clustering", "credits"),
			"Sum of the number of credits billed for automatic reclustering over the last 24 hours.",
			[]string{labelTableName, labelTableID, labelSchemaName, labelSchemaID, labelDatabaseName, labelDatabaseID},
			nil,
		),
		autoClusteringBytes: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "auto_clustering", "bytes"),
			"Sum of the number of bytes reclustered during automatic reclustering over the last 24 hours.",
			[]string{labelTableName, labelTableID, labelSchemaName, labelSchemaID, labelDatabaseName, labelDatabaseID},
			nil,
		),
		autoClusteringRows: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "auto_clustering", "rows"),
			"Sum of the number of rows clustered during automatic reclustering over the last 24 hours.",
			[]string{labelTableName, labelTableID, labelSchemaName, labelSchemaID, labelDatabaseName, labelDatabaseID},
			nil,
		),
		tableActiveBytes: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "table", "active_bytes"),
			"Sum of active bytes owned by the table.",
			[]string{labelTableName, labelTableID, labelSchemaName, labelSchemaID, labelDatabaseName, labelDatabaseID},
			nil,
		),
		tableTimeTravelBytes: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "table", "time_travel_bytes"),
			"Sum of bytes in Time Travel state owned by the table.",
			[]string{labelTableName, labelTableID, labelSchemaName, labelSchemaID, labelDatabaseName, labelDatabaseID},
			nil,
		),
		tableFailsafeBytes: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "table", "failsafe_bytes"),
			"Sum of bytes in Fail-Safe state owned by the table.",
			[]string{labelTableName, labelTableID, labelSchemaName, labelSchemaID, labelDatabaseName, labelDatabaseID},
			nil,
		),
		tableCloneBytes: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "table", "clone_bytes"),
			"Sum of bytes owned by the table that are retained after deletion because they are referenced by one or more clones.",
			[]string{labelTableName, labelTableID, labelSchemaName, labelSchemaID, labelDatabaseName, labelDatabaseID},
			nil,
		),
		tableDeletedTables: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "table", "deleted_tables"),
			"Number of tables that have been purged from storage.",
			nil,
			nil,
		),
		replicationUsedCredits: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "db_replication", "used_credits"),
			"Sum of the number of credits used for database replication over the last 24 hours.",
			[]string{labelDatabaseName, labelDatabaseID},
			nil,
		),
		replicationTransferredBytes: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "db_replication", "transferred_bytes"),
			"Sum of the number of transferred bytes for database replication over the last 24 hours.",
			[]string{labelDatabaseName, labelDatabaseID},
			nil,
		),
		up: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "", "up"),
			"Metric indicating the status of the exporter collection. 1 indicates that the connection Snowflake was successful, and all available metrics were collected. "+
				"0 indicates that the exporter failed to collect 1 or more metrics, due to an inability to connect to Snowflake.",
			nil,
			nil,
		),
	}
}

// Describe returns all metric descriptions of the collector by emitting them down the provided channel.
// It implements prometheus.Collector.
func (c *Collector) Describe(descs chan<- *prometheus.Desc) {
	descs <- c.storageBytes
	descs <- c.stageBytes
	descs <- c.failsafeBytes
	descs <- c.databaseBytes
	descs <- c.databaseFailsafeBytes
	descs <- c.usedComputeCredits
	descs <- c.usedCloudServicesCredits
	descs <- c.warehouseUsedComputeCredits
	descs <- c.warehouseUsedCloudServicesCredits
	descs <- c.logins
	descs <- c.successfulLogins
	descs <- c.failedLogins
	descs <- c.warehouseExecutedQueryLoad
	descs <- c.warehouseOverloadedQueueLoad
	descs <- c.warehouseProvisioningQueueLoad
	descs <- c.warehouseBlockedQueryLoad
	descs <- c.autoClusteringCredits
	descs <- c.autoClusteringBytes
	descs <- c.autoClusteringRows
	descs <- c.tableActiveBytes
	descs <- c.tableTimeTravelBytes
	descs <- c.tableFailsafeBytes
	descs <- c.tableCloneBytes
	descs <- c.tableDeletedTables
	descs <- c.replicationUsedCredits
	descs <- c.replicationTransferredBytes
	descs <- c.up
}

// Collect collects all metrics for this collector, and emits them through the provided channel.
// It implements prometheus.Collector.
func (c *Collector) Collect(metrics chan<- prometheus.Metric) {
	level.Debug(c.logger).Log("msg", "Collecting metrics.")

	// Create a WaitGroup to block closing the database until all goroutines are done
	var wg sync.WaitGroup

	var up float64 = 1
	// Open a new connection to the database each time; This makes the connection more robust to transient failures
	connectionString, err := c.config.snowflakeConnectionString()
	if err != nil {
		level.Error(c.logger).Log("msg", "Failed to generate connection string.", "err", err)
		// Emit up metric here, to indicate connection failed.
		metrics <- prometheus.MustNewConstMetric(c.up, prometheus.GaugeValue, 0)
		return
	}
	db, err := c.openDatabase(connectionString)
	if err != nil {
		level.Error(c.logger).Log("msg", "Failed to connect to Snowflake.", "err", err)
		// Emit up metric here, to indicate connection failed.
		metrics <- prometheus.MustNewConstMetric(c.up, prometheus.GaugeValue, 0)
		return
	}
	defer db.Close()

	wg.Add(1)
	go func() {
		if err := c.collectStorageMetrics(db, metrics); err != nil {
			level.Error(c.logger).Log("msg", "Failed to collect storage metrics.", "err", err)
			up = 0
		}
		wg.Done()
	}()

	wg.Add(1)
	go func() {
		if err := c.collectDatabaseStorageMetrics(db, metrics); err != nil {
			level.Error(c.logger).Log("msg", "Failed to collect database storage metrics.", "err", err)
			up = 0
		}
		wg.Done()
	}()

	wg.Add(1)
	go func() {
		if err := c.collectCreditMetrics(db, metrics); err != nil {
			level.Error(c.logger).Log("msg", "Failed to collect credit metrics.", "err", err)
			up = 0
		}
		wg.Done()
	}()

	wg.Add(1)
	go func() {
		if err := c.collectWarehouseCreditMetrics(db, metrics); err != nil {
			level.Error(c.logger).Log("msg", "Failed to collect warehouse credit metrics.", "err", err)
			up = 0
		}
		wg.Done()
	}()

	wg.Add(1)
	go func() {
		if err := c.collectLoginMetrics(db, metrics); err != nil {
			level.Error(c.logger).Log("msg", "Failed to collect login metrics.", "err", err)
			up = 0
		}
		wg.Done()
	}()

	wg.Add(1)
	go func() {
		if err := c.collectWarehouseLoadMetrics(db, metrics); err != nil {
			level.Error(c.logger).Log("msg", "Failed to collect warehouse load metrics.", "err", err)
			up = 0
		}
		wg.Done()
	}()

	wg.Add(1)
	go func() {
		if err := c.collectAutoClusteringMetrics(db, metrics); err != nil {
			level.Error(c.logger).Log("msg", "Failed to collect autoclustering metrics.", "err", err)
			up = 0
		}
		wg.Done()
	}()

	wg.Add(1)
	go func() {
		if err := c.collectTableStorageMetrics(db, metrics); err != nil {
			level.Error(c.logger).Log("msg", "Failed to collect table storage metrics.", "err", err)
			up = 0
		}
		wg.Done()
	}()

	if !c.config.ExcludeDeleted {
		wg.Add(1)
		go func() {
			if err := c.collectDeletedTablesMetrics(db, metrics); err != nil {
				level.Error(c.logger).Log("msg", "Failed to collect deleted tables metrics.", "err", err)
				up = 0
			}
			wg.Done()
		}()
	}

	wg.Add(1)
	go func() {
		if err := c.collectReplicationMetrics(db, metrics); err != nil {
			level.Error(c.logger).Log("msg", "Failed to collect replication metrics.", "err", err)
			up = 0
		}
		wg.Done()
	}()

	wg.Wait()
	metrics <- prometheus.MustNewConstMetric(c.up, prometheus.GaugeValue, up)
	level.Debug(c.logger).Log("msg", "Finished collecting metrics.")
}

func (c *Collector) collectStorageMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	level.Debug(c.logger).Log("msg", "Collecting storage metrics.")
	rows, err := db.Query(storageMetricQuery)
	level.Debug(c.logger).Log("msg", "Done querying storage metrics.")
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	if !rows.Next() {
		if err := rows.Err(); err != nil {
			return fmt.Errorf("failed to fetch row: %w", rows.Err())
		}
		return fmt.Errorf("expected a single row to be returned, but none was found")
	}

	var storageBytes, stageBytes, failsafeBytes sql.NullFloat64
	if err := rows.Scan(&storageBytes, &stageBytes, &failsafeBytes); err != nil {
		return fmt.Errorf("failed to scan row: %w", err)
	}

	if storageBytes.Valid {
		metrics <- prometheus.MustNewConstMetric(c.storageBytes, prometheus.GaugeValue, storageBytes.Float64)
	}
	if stageBytes.Valid {
		metrics <- prometheus.MustNewConstMetric(c.stageBytes, prometheus.GaugeValue, stageBytes.Float64)
	}
	if failsafeBytes.Valid {
		metrics <- prometheus.MustNewConstMetric(c.failsafeBytes, prometheus.GaugeValue, failsafeBytes.Float64)
	}

	level.Debug(c.logger).Log("msg", "Finished collecting storage metrics.")
	return rows.Err()
}

func (c *Collector) collectDatabaseStorageMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	level.Debug(c.logger).Log("msg", "Collecting database storage metrics.")
	rows, err := db.Query(databaseStorageMetricQuery)
	level.Debug(c.logger).Log("msg", "Done querying database storage metrics.")
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var dbName, dbID sql.NullString
		var databaseBytes, failsafeBytes sql.NullFloat64
		if err := rows.Scan(&dbName, &dbID, &databaseBytes, &failsafeBytes); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		if databaseBytes.Valid {
			metrics <- prometheus.MustNewConstMetric(c.databaseBytes, prometheus.GaugeValue, databaseBytes.Float64, dbName.String, dbID.String)
		}
		if failsafeBytes.Valid {
			metrics <- prometheus.MustNewConstMetric(c.databaseFailsafeBytes, prometheus.GaugeValue, failsafeBytes.Float64, dbName.String, dbID.String)
		}
	}

	level.Debug(c.logger).Log("msg", "Finished collecting database storage metrics.")
	return rows.Err()
}

func (c *Collector) collectCreditMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	level.Debug(c.logger).Log("msg", "Collecting credit metrics.")
	rows, err := db.Query(creditMetricQuery)
	level.Debug(c.logger).Log("msg", "Done querying credit metrics.")
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var serviceType, serviceName sql.NullString
		var computeCreditsUsedAvg, cloudServiceCreditsUsedAvg sql.NullFloat64
		if err := rows.Scan(&serviceType, &serviceName, &computeCreditsUsedAvg, &cloudServiceCreditsUsedAvg); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		if computeCreditsUsedAvg.Valid {
			metrics <- prometheus.MustNewConstMetric(c.usedComputeCredits, prometheus.GaugeValue, computeCreditsUsedAvg.Float64, serviceType.String, serviceName.String)
		}
		if cloudServiceCreditsUsedAvg.Valid {
			metrics <- prometheus.MustNewConstMetric(c.usedCloudServicesCredits, prometheus.GaugeValue, cloudServiceCreditsUsedAvg.Float64, serviceType.String, serviceName.String)
		}
	}

	level.Debug(c.logger).Log("msg", "Finished collecting credit metrics.")
	return rows.Err()
}

func (c *Collector) collectWarehouseCreditMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	level.Debug(c.logger).Log("msg", "Collecting warehouse credit metrics.")
	rows, err := db.Query(warehouseCreditMetricQuery)
	level.Debug(c.logger).Log("msg", "Done querying warehouse credit metrics.")
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var warehouseName, warehouseID sql.NullString
		var computeCreditsUsedAvg, cloudServiceCreditsUsedAvg sql.NullFloat64
		if err := rows.Scan(&warehouseName, &warehouseID, &computeCreditsUsedAvg, &cloudServiceCreditsUsedAvg); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		if computeCreditsUsedAvg.Valid {
			metrics <- prometheus.MustNewConstMetric(c.warehouseUsedComputeCredits, prometheus.GaugeValue, computeCreditsUsedAvg.Float64, warehouseName.String, warehouseID.String)
		}
		if cloudServiceCreditsUsedAvg.Valid {
			metrics <- prometheus.MustNewConstMetric(c.warehouseUsedCloudServicesCredits, prometheus.GaugeValue, cloudServiceCreditsUsedAvg.Float64, warehouseName.String, warehouseID.String)
		}
	}

	level.Debug(c.logger).Log("msg", "Finished collecting warehouse credit metrics.")
	return rows.Err()
}

func (c *Collector) collectLoginMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	level.Debug(c.logger).Log("msg", "Collecting login metrics.")
	rows, err := db.Query(loginMetricQuery)
	level.Debug(c.logger).Log("msg", "Done querying login metrics.")
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var clientType, clientVersion sql.NullString
		var failures, successes, total sql.NullFloat64
		if err := rows.Scan(&clientType, &clientVersion, &failures, &successes, &total); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		// Divided by 24 to get the per-hour average
		if total.Valid {
			metrics <- prometheus.MustNewConstMetric(c.logins, prometheus.GaugeValue, total.Float64/24, clientType.String, clientVersion.String)
		}
		if failures.Valid {
			metrics <- prometheus.MustNewConstMetric(c.failedLogins, prometheus.GaugeValue, failures.Float64/24, clientType.String, clientVersion.String)
		}
		if successes.Valid {
			metrics <- prometheus.MustNewConstMetric(c.successfulLogins, prometheus.GaugeValue, successes.Float64/24, clientType.String, clientVersion.String)
		}
	}

	level.Debug(c.logger).Log("msg", "Finished collecting login metrics.")
	return rows.Err()
}

func (c *Collector) collectWarehouseLoadMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	level.Debug(c.logger).Log("msg", "Collecting warehouse load metrics.")
	rows, err := db.Query(warehouseLoadMetricQuery)
	level.Debug(c.logger).Log("msg", "Done querying warehouse load metrics.")
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var warehouseName, warehouseID sql.NullString
		var avgRunning, avgQueued, avgQueuedProvisioning, avgBlocked sql.NullFloat64
		if err := rows.Scan(&warehouseName, &warehouseID, &avgRunning, &avgQueued, &avgQueuedProvisioning, &avgBlocked); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		if avgRunning.Valid {
			metrics <- prometheus.MustNewConstMetric(c.warehouseExecutedQueryLoad, prometheus.GaugeValue, avgRunning.Float64, warehouseName.String, warehouseID.String)
		}
		if avgQueued.Valid {
			metrics <- prometheus.MustNewConstMetric(c.warehouseOverloadedQueueLoad, prometheus.GaugeValue, avgQueued.Float64, warehouseName.String, warehouseID.String)
		}
		if avgQueuedProvisioning.Valid {
			metrics <- prometheus.MustNewConstMetric(c.warehouseProvisioningQueueLoad, prometheus.GaugeValue, avgQueuedProvisioning.Float64, warehouseName.String, warehouseID.String)
		}
		if avgBlocked.Valid {
			metrics <- prometheus.MustNewConstMetric(c.warehouseBlockedQueryLoad, prometheus.GaugeValue, avgBlocked.Float64, warehouseName.String, warehouseID.String)
		}
	}

	level.Debug(c.logger).Log("msg", "Finished collecting warehouse load metrics.")
	return rows.Err()
}

func (c *Collector) collectAutoClusteringMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	level.Debug(c.logger).Log("msg", "Collecting auto-clustering metrics.")
	rows, err := db.Query(autoClusteringMetricQuery)
	level.Debug(c.logger).Log("msg", "Done querying auto-clustering metrics.")
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var tableName, tableID, databaseName, databaseID, schemaName, schemaID sql.NullString
		var creditsUsed, bytesReclustered, rowsReclustered sql.NullFloat64
		if err := rows.Scan(&tableName, &tableID, &schemaName, &schemaID, &databaseName, &databaseID,
			&creditsUsed, &bytesReclustered, &rowsReclustered); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		if creditsUsed.Valid {
			metrics <- prometheus.MustNewConstMetric(c.autoClusteringCredits, prometheus.GaugeValue, creditsUsed.Float64,
				tableName.String, tableID.String, schemaName.String, schemaID.String, databaseName.String, databaseID.String)
		}
		if bytesReclustered.Valid {
			metrics <- prometheus.MustNewConstMetric(c.autoClusteringBytes, prometheus.GaugeValue, bytesReclustered.Float64,
				tableName.String, tableID.String, schemaName.String, schemaID.String, databaseName.String, databaseID.String)
		}
		if rowsReclustered.Valid {
			metrics <- prometheus.MustNewConstMetric(c.autoClusteringRows, prometheus.GaugeValue, rowsReclustered.Float64,
				tableName.String, tableID.String, schemaName.String, schemaID.String, databaseName.String, databaseID.String)
		}
	}

	level.Debug(c.logger).Log("msg", "Finished collecting auto-clustering metrics.")
	return rows.Err()
}

func (c *Collector) collectTableStorageMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	var rows *sql.Rows
	var err error
	if c.config.ExcludeDeleted {
		level.Debug(c.logger).Log("msg", "Collecting table storage metrics excluding deleted tables.")
		rows, err = db.Query(tableStorageExcludeDeletedMetricQuery)
		if err != nil {
			return fmt.Errorf("failed to query metrics: %w", err)
		}
	} else {
		level.Debug(c.logger).Log("msg", "Collecting table storage metrics.")
		rows, err = db.Query(tableStorageMetricQuery)
		if err != nil {
			return fmt.Errorf("failed to query metrics: %w", err)
		}
	}
	level.Debug(c.logger).Log("msg", "Done querying table storage metrics.")
	defer rows.Close()

	for rows.Next() {
		var tableName, tableID, databaseName, databaseID, schemaName, schemaID sql.NullString
		var activeBytes, timeTravelBytes, failsafeBytes, cloneBytes sql.NullFloat64
		if err := rows.Scan(&tableName, &tableID, &schemaName, &schemaID, &databaseName, &databaseID,
			&activeBytes, &timeTravelBytes, &failsafeBytes, &cloneBytes); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		if activeBytes.Valid {
			metrics <- prometheus.MustNewConstMetric(c.tableActiveBytes, prometheus.GaugeValue, activeBytes.Float64,
				tableName.String, tableID.String, schemaName.String, schemaID.String, databaseName.String, databaseID.String)
		}
		if timeTravelBytes.Valid {
			metrics <- prometheus.MustNewConstMetric(c.tableTimeTravelBytes, prometheus.GaugeValue, timeTravelBytes.Float64,
				tableName.String, tableID.String, schemaName.String, schemaID.String, databaseName.String, databaseID.String)
		}
		if failsafeBytes.Valid {
			metrics <- prometheus.MustNewConstMetric(c.tableFailsafeBytes, prometheus.GaugeValue, failsafeBytes.Float64,
				tableName.String, tableID.String, schemaName.String, schemaID.String, databaseName.String, databaseID.String)
		}
		if cloneBytes.Valid {
			metrics <- prometheus.MustNewConstMetric(c.tableCloneBytes, prometheus.GaugeValue, cloneBytes.Float64,
				tableName.String, tableID.String, schemaName.String, schemaID.String, databaseName.String, databaseID.String)
		}
	}

	level.Debug(c.logger).Log("msg", "Finished collecting table storage metrics.")
	return rows.Err()
}

func (c *Collector) collectDeletedTablesMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	level.Debug(c.logger).Log("msg", "Collecting deleted table metrics.")
	rows, err := db.Query(deletedTablesMetricQuery)
	level.Debug(c.logger).Log("msg", "Done querying deleted table metrics.")
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var deletedTables sql.NullFloat64
		if err := rows.Scan(&deletedTables); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		if deletedTables.Valid {
			metrics <- prometheus.MustNewConstMetric(c.tableDeletedTables, prometheus.GaugeValue, deletedTables.Float64)
		}
	}

	level.Debug(c.logger).Log("msg", "Finished collecting deleted table metrics.")
	return rows.Err()
}

func (c *Collector) collectReplicationMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	level.Debug(c.logger).Log("msg", "Collecting replication metrics.")
	rows, err := db.Query(replicationMetricQuery)
	level.Debug(c.logger).Log("msg", "Done querying replication metrics.")
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var databaseName, databaseID sql.NullString
		var creditsUsed, bytesTransferred sql.NullFloat64
		if err := rows.Scan(&databaseName, &databaseID, &creditsUsed, &bytesTransferred); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		if creditsUsed.Valid {
			metrics <- prometheus.MustNewConstMetric(c.replicationUsedCredits, prometheus.GaugeValue, creditsUsed.Float64, databaseName.String, databaseID.String)
		}
		if bytesTransferred.Valid {
			metrics <- prometheus.MustNewConstMetric(c.replicationTransferredBytes, prometheus.GaugeValue, bytesTransferred.Float64, databaseName.String, databaseID.String)
		}
	}

	level.Debug(c.logger).Log("msg", "Finished collecting replication metrics.")
	return rows.Err()
}
