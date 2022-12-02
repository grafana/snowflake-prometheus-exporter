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
	"bytes"
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

func TestCollector_Collect(t *testing.T) {
	t.Run("Metrics match expected", func(t *testing.T) {
		db, mock := createMockDB(t)

		col := NewCollector(log.NewJSONLogger(os.Stdout), &Config{})
		col.openDatabase = func(_ string) (*sql.DB, error) { return db, nil }

		f, err := os.Open(filepath.Join("testdata", "all_metrics.prom"))
		require.NoError(t, err)
		defer f.Close()

		require.NoError(t, testutil.CollectAndCompare(col, f))

		require.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("Metrics have no lint errors", func(t *testing.T) {
		db, mock := createMockDB(t)

		col := NewCollector(log.NewJSONLogger(os.Stdout), &Config{})
		col.openDatabase = func(_ string) (*sql.DB, error) { return db, nil }

		p, err := testutil.CollectAndLint(col)
		require.NoError(t, err)
		require.Empty(t, p)

		require.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("All queries fail", func(t *testing.T) {
		db, mock := createQueryErrMockDB(t)

		col := NewCollector(log.NewJSONLogger(os.Stdout), &Config{})
		col.openDatabase = func(_ string) (*sql.DB, error) { return db, nil }

		// No metrics should be collected; An empty buffer should match the output
		// of the scraped metrics
		err := testutil.CollectAndCompare(col, &bytes.Buffer{})
		require.NoError(t, err)

		// Checks that db is closed and all queries are called
		require.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("Database connection fails", func(t *testing.T) {
		col := NewCollector(log.NewJSONLogger(os.Stdout), &Config{})

		openErr := errors.New("failed to open database")
		col.openDatabase = func(_ string) (*sql.DB, error) { return nil, openErr }

		// No metrics should be scraped if the database fails to open
		err := testutil.CollectAndCompare(col, &bytes.Buffer{})
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

		col := NewCollector(log.NewJSONLogger(os.Stdout), &Config{})
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

		col := NewCollector(log.NewJSONLogger(os.Stdout), &Config{})
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

func newRows(t *testing.T, rows [][]string) *sqlmock.Rows {
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
			rowVals = append(rowVals, sql.NullString{
				String: s,
				Valid:  true,
			})
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

	mock.ExpectQuery(storageMetricQuery).
		WillReturnRows(
			newRows(t, [][]string{
				{"1028.0", "2048.0", "4096.0"},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(databaseStorageMetricQuery).
		WillReturnRows(
			newRows(t, [][]string{
				{testDB1Name, testDB1ID, "1028.0", "2048.0"},
				{testDB2Name, testDB2ID, "1028.0", "2048.0"},
			}),
		).RowsWillBeClosed()

	mock.ExpectQuery(creditMetricQuery).
		WillReturnRows(
			newRows(t, [][]string{
				{testService1Name, testService1Type, "0.5", "0.5"},
				{testService2Name, testService2Type, "0.25", "0.125"},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(warehouseCreditMetricQuery).
		WillReturnRows(
			newRows(t, [][]string{
				{testWarehouse1Name, testWarehouse1ID, "56", "12"},
				{testWarehouse2Name, testWarehouse2ID, "89", "45"},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(loginMetricQuery).
		WillReturnRows(
			newRows(t, [][]string{
				{testClient1Type, testClient1Version, "24", "216", "240"},
				{testClient2Type, testClient2Version, "240", "2160", "2400"},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(warehouseLoadMetricQuery).
		WillReturnRows(
			newRows(t, [][]string{
				{testWarehouse1Name, testWarehouse1ID, "80", "40", "20", "10"},
				{testWarehouse2Name, testWarehouse2ID, "1234", "123", "234", "534"},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(autoClusteringMetricQuery).
		WillReturnRows(
			newRows(t, [][]string{
				{
					testTableName, testTableID, testSchemaName, testSchemaID, testDB1Name, testDB1ID,
					"1.5", "2048", "4096",
				},
				{
					testTableName, testTableID, testSchemaName, testSchemaID, testDB2Name, testDB2ID,
					"1.5", "8192", "16384",
				},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(tableStorageMetricQuery).
		WillReturnRows(
			newRows(t, [][]string{
				{
					testTableName, testTableID, testSchemaName, testSchemaID, testDB1Name, testDB1ID,
					"1028", "2048", "4096", "8192",
				},
				{
					testTableName, testTableID, testSchemaName, testSchemaID, testDB2Name, testDB2ID,
					"16384", "32768", "65536", "131072",
				},
			}),
		).
		RowsWillBeClosed()

	mock.ExpectQuery(replicationMetricQuery).
		WillReturnRows(
			newRows(t, [][]string{
				{
					testDB1Name, testDB1ID,
					"1028", "2048",
				},
				{
					testDB2Name, testDB2ID,
					"16384", "32768",
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
	mock.ExpectQuery(replicationMetricQuery).WillReturnError(queryErr)

	mock.ExpectClose()

	return db, mock
}
