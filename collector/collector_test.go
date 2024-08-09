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
	"database/sql/driver"
	"errors"
	"os"
	"path/filepath"
	"strconv"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/go-kit/log"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/testutil"
	"github.com/stretchr/testify/require"
)

var ExampleConfig = &Config{
	AccountName: "defaultaccount",
	Username:    "defaultuser",
	Password:    "defaultpassword",
	Warehouse:   "defaultwarehouse",
	Role:        "ACCOUNTADMIN",
}

func TestCollector_Collect(t *testing.T) {
	t.Run("Metrics match expected", func(t *testing.T) {
		db, mock := createMockDB(t)
		mock.MatchExpectationsInOrder(false)

		col := NewCollector(log.NewJSONLogger(os.Stdout), ExampleConfig)
		col.openDatabase = func(_ string) (*sql.DB, error) { return db, nil }

		f, err := os.Open(filepath.Join("testdata", "all_metrics.prom"))
		require.NoError(t, err)
		defer f.Close()

		require.NoError(t, testutil.CollectAndCompare(col, f))

		require.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("Metrics have no lint errors", func(t *testing.T) {
		db, mock := createMockDB(t)
		mock.MatchExpectationsInOrder(false)

		col := NewCollector(log.NewJSONLogger(os.Stdout), ExampleConfig)
		col.openDatabase = func(_ string) (*sql.DB, error) { return db, nil }

		p, err := testutil.CollectAndLint(col)
		require.NoError(t, err)
		require.Empty(t, p)

		require.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("All queries fail", func(t *testing.T) {
		db, mock := createQueryErrMockDB(t)
		mock.MatchExpectationsInOrder(false)

		col := NewCollector(log.NewJSONLogger(os.Stdout), ExampleConfig)
		col.openDatabase = func(_ string) (*sql.DB, error) { return db, nil }

		f, err := os.Open(filepath.Join("testdata", "query_failure.prom"))
		require.NoError(t, err)
		defer f.Close()

		// No metrics should be collected; An empty buffer should match the output
		// of the scraped metrics
		err = testutil.CollectAndCompare(col, f)
		require.NoError(t, err)

		// Checks that db is closed and all queries are called
		require.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("Database connection fails", func(t *testing.T) {
		col := NewCollector(log.NewJSONLogger(os.Stdout), ExampleConfig)

		openErr := errors.New("failed to open database")
		col.openDatabase = func(_ string) (*sql.DB, error) { return nil, openErr }

		f, err := os.Open(filepath.Join("testdata", "query_failure.prom"))
		require.NoError(t, err)
		defer f.Close()

		// No metrics should be scraped if the database fails to open
		err = testutil.CollectAndCompare(col, f)
		require.NoError(t, err)
	})
}

func TestCollector_collectStorageMetrics(t *testing.T) {
	t.Run("Row error", func(t *testing.T) {
		db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherEqual))
		require.NoError(t, err)

		rowErr := errors.New("failed for inexplicable reasons")

		mock.ExpectQuery(storageMetricQuery).
			WillReturnRows(
				sqlmock.NewRows([]string{"STORAGE_BYTES", "STAGE_BYTES", "FAILSAFE_BYTES"}).AddRow(
					sql.NullString{}, sql.NullString{}, sql.NullString{},
				).RowError(0, rowErr),
			).
			RowsWillBeClosed()

		col := NewCollector(log.NewJSONLogger(os.Stdout), ExampleConfig)
		col.openDatabase = func(_ string) (*sql.DB, error) { return db, nil }

		metricChan := make(chan prometheus.Metric, 3)
		collectionDoneChan := make(chan struct{})

		go func() {
			err := col.collectStorageMetrics(db, metricChan)
			require.ErrorContains(t, err, "failed to fetch row:")
			require.ErrorIs(t, err, rowErr)
			close(collectionDoneChan)
		}()

		select {
		case <-collectionDoneChan: // OK
		case <-time.After(time.Second):
			require.Fail(t, "Timed out waiting for collectStorageMetrics to complete")
		}
	})

	t.Run("No rows returned", func(t *testing.T) {
		db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherEqual))
		require.NoError(t, err)

		mock.ExpectQuery(storageMetricQuery).
			WillReturnRows(
				sqlmock.NewRows([]string{"STORAGE_BYTES", "STAGE_BYTES", "FAILSAFE_BYTES"}),
			).
			RowsWillBeClosed()

		col := NewCollector(log.NewJSONLogger(os.Stdout), ExampleConfig)
		col.openDatabase = func(_ string) (*sql.DB, error) { return db, nil }

		metricChan := make(chan prometheus.Metric, 3)
		collectionDoneChan := make(chan struct{})

		go func() {
			err := col.collectStorageMetrics(db, metricChan)
			require.Equal(t, "expected a single row to be returned, but none was found", err.Error())
			close(collectionDoneChan)
		}()

		select {
		case <-collectionDoneChan: // OK
		case <-time.After(time.Second):
			require.Fail(t, "Time out waiting for collectStorageMetrics to complete")
		}
	})
}

func newRows(t *testing.T, rows [][]*string) *sqlmock.Rows {
	numRows := len(rows[0])

	for _, row := range rows {
		require.Equal(t, len(row), numRows, "Number of returned values must be equal for all rows")
	}

	cols := []string{}
	for i := 0; i < numRows; i++ {
		cols = append(cols, strconv.FormatInt(int64(i), 10))
	}

	sqlRows := sqlmock.NewRows(cols)

	for _, row := range rows {
		rowVals := []driver.Value{}
		for _, s := range row {
			if s != nil {
				rowVals = append(rowVals, sql.NullString{
					String: *s,
					Valid:  true,
				})
			} else {
				rowVals = append(rowVals, sql.NullString{
					String: "",
					Valid:  false,
				})
			}
		}

		sqlRows.AddRow(rowVals...)
	}

	return sqlRows
}

func createMockDB(t *testing.T) (*sql.DB, sqlmock.Sqlmock) {
	t.Helper()

	testDB1Name := "mock_db"
	testDB1ID := "1"
	testDB2Name := "another_mock_db"
	testDB2ID := "2"

	testSchemaName := "mock_schema"
	testSchemaID := "4"

	testTableName := "mock_table"
	testTableID := "3"

	testWarehouse1Name := "mock_warehouse"
	testWarehouse1ID := "10"
	testWarehouse2Name := "another_mock_warehouse"
	testWarehouse2ID := "11"

	testService1Name := "mock_service"
	testService2Name := "another_mock_service"
	testService1Type := "mock_service_type"
	testService2Type := "another_mock_service_type"

	testClient1Type := "mock_client_type"
	testClient2Type := "another_mock_client_type"
	testClient1Version := "v0.1.0"
	testClient2Version := "v1.0.0"

	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherEqual))
	require.NoError(t, err)

	val1 := "1028.0"
	val2 := "2048.0"
	val3 := "4096.0"
	val4 := "0.5"
	val5 := "0.25"
	val6 := "0.125"
	val7 := "56"
	val8 := "12"
	val9 := "89"
	val10 := "45"
	val11 := "24"
	val12 := "216"
	val13 := "240"
	val14 := "2160"
	val15 := "2400"
	val16 := "80"
	val17 := "40"
	val18 := "20"
	val19 := "10"
	val20 := "1234"
	val21 := "123"
	val22 := "234"
	val23 := "534"
	val24 := "1.5"
	val25 := "8192"
	val26 := "16384"
	val27 := "32768"
	val28 := "65536"
	val29 := "131072"

	mock.ExpectQuery(storageMetricQuery).
		WillReturnRows(
			newRows(t, [][]*string{
				{&val1, &val2, &val3},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(databaseStorageMetricQuery).
		WillReturnRows(
			newRows(t, [][]*string{
				{&testDB1Name, &testDB1ID, &val1, &val2},
				{&testDB2Name, &testDB2ID, &val1, &val2},
			}),
		).RowsWillBeClosed()

	mock.ExpectQuery(creditMetricQuery).
		WillReturnRows(
			newRows(t, [][]*string{
				{&testService1Name, &testService1Type, &val4, &val4},
				{&testService2Name, &testService2Type, &val5, &val6},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(warehouseCreditMetricQuery).
		WillReturnRows(
			newRows(t, [][]*string{
				{&testWarehouse1Name, &testWarehouse1ID, &val7, &val8},
				{&testWarehouse2Name, &testWarehouse2ID, &val9, &val10},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(loginMetricQuery).
		WillReturnRows(
			newRows(t, [][]*string{
				{&testClient1Type, &testClient1Version, &val11, &val12, &val13},
				{&testClient2Type, &testClient2Version, &val13, &val14, &val15},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(warehouseLoadMetricQuery).
		WillReturnRows(
			newRows(t, [][]*string{
				{&testWarehouse1Name, &testWarehouse1ID, &val16, &val17, &val18, &val19},
				{&testWarehouse2Name, &testWarehouse2ID, &val20, &val21, &val22, &val23},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(autoClusteringMetricQuery).
		WillReturnRows(
			newRows(t, [][]*string{
				{
					&testTableName, &testTableID, &testSchemaName, &testSchemaID, &testDB1Name, &testDB1ID,
					&val24, &val2, &val3,
				},
				{
					&testTableName, &testTableID, &testSchemaName, &testSchemaID, &testDB2Name, &testDB2ID,
					&val24, &val25, &val26,
				},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(tableStorageMetricQuery).
		WillReturnRows(
			newRows(t, [][]*string{
				{
					&testTableName, &testTableID, &testSchemaName, &testSchemaID, &testDB1Name, &testDB1ID,
					&val1, &val2, &val3, &val25,
				},
				{
					&testTableName, &testTableID, nil, &testSchemaID, &testDB2Name, &testDB2ID,
					&val26, &val27, &val28, &val29,
				},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(deletedTablesMetricQuery).
		WillReturnRows(
			newRows(t, [][]*string{
				{
					&val19,
				},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(replicationMetricQuery).
		WillReturnRows(
			newRows(t, [][]*string{
				{
					&testDB1Name, &testDB1ID,
					&val1, &val2,
				},
				{
					&testDB2Name, &testDB2ID,
					&val26, &val27,
				},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectClose()

	return db, mock
}

func createQueryErrMockDB(t *testing.T) (*sql.DB, sqlmock.Sqlmock) {
	t.Helper()

	queryErr := errors.New("the query failed for inexplicable reasons")

	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherEqual))
	require.NoError(t, err)

	mock.ExpectQuery(storageMetricQuery).WillReturnError(queryErr)
	mock.ExpectQuery(databaseStorageMetricQuery).WillReturnError(queryErr)
	mock.ExpectQuery(creditMetricQuery).WillReturnError(queryErr)
	mock.ExpectQuery(warehouseCreditMetricQuery).WillReturnError(queryErr)
	mock.ExpectQuery(loginMetricQuery).WillReturnError(queryErr)
	mock.ExpectQuery(warehouseLoadMetricQuery).WillReturnError(queryErr)
	mock.ExpectQuery(autoClusteringMetricQuery).WillReturnError(queryErr)
	mock.ExpectQuery(tableStorageMetricQuery).WillReturnError(queryErr)
	mock.ExpectQuery(deletedTablesMetricQuery).WillReturnError(queryErr)
	mock.ExpectQuery(replicationMetricQuery).WillReturnError(queryErr)

	mock.ExpectClose()

	return db, mock
}
