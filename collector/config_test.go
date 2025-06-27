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
	"testing"

	"github.com/stretchr/testify/require"
)

func TestConfig_Validate(t *testing.T) {
	testCases := []struct {
		name        string
		inputConfig Config
		expectedErr error
	}{
		{
			name: "No account name",
			inputConfig: Config{
				Username:  "some_user",
				Password:  "some_pass",
				Role:      "ACCOUNTADMIN",
				Warehouse: "ACCOUNT_WH",
			},
			expectedErr: errNoAccountName,
		},
		{
			name: "No username",
			inputConfig: Config{
				AccountName: "some_account",
				Password:    "some_pass",
				Role:        "ACCOUNTADMIN",
				Warehouse:   "ACCOUNT_WH",
			},
			expectedErr: errNoUsername,
		},
		{
			name: "No password or private key path",
			inputConfig: Config{
				AccountName: "some_account",
				Username:    "some_user",
				Role:        "ACCOUNTADMIN",
				Warehouse:   "ACCOUNT_WH",
			},
			expectedErr: errNoAuth,
		},
		{
			name: "No Role",
			inputConfig: Config{
				AccountName: "some_account",
				Username:    "some_user",
				Password:    "some_pass",
				Warehouse:   "ACCOUNT_WH",
			},
			expectedErr: errNoRole,
		},
		{
			name: "No Warehouse",
			inputConfig: Config{
				AccountName: "some_account",
				Username:    "some_user",
				Password:    "some_pass",
				Role:        "ACCOUNTADMIN",
			},
			expectedErr: errNoWarehouse,
		},
		{
			name: "Valid config - password",
			inputConfig: Config{
				AccountName: "some_account",
				Username:    "some_user",
				Password:    "some_pass",
				Role:        "ACCOUNTADMIN",
				Warehouse:   "ACCOUNT_WH",
			},
		},
		{
			name: "Valid config - encrypted RSA",
			inputConfig: Config{
				AccountName:        "some-account",
				Username:           "some-user",
				Role:               "ACCOUNTADMIN",
				Warehouse:          "some-warehouse",
				PrivateKeyPath:     "some/path/rsa_key.p8",
				PrivateKeyPassword: "some-password",
			},
		},
		{
			name: "Valid config - unencrypted RSA",
			inputConfig: Config{
				AccountName:    "some-account",
				Username:       "some-user",
				Role:           "ACCOUNTADMIN",
				Warehouse:      "some-warehouse",
				PrivateKeyPath: "some/path/rsa_key.p8",
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			err := tc.inputConfig.Validate()
			if tc.expectedErr != nil {
				require.Equal(t, tc.expectedErr, err)
			} else {
				require.Nil(t, err)
			}
		})
	}
}

func TestConfig_snowflakeConnectionString(t *testing.T) {
	testCases := []struct {
		name           string
		inputConfig    Config
		expectedString string
	}{
		{
			name: "Valid config",
			inputConfig: Config{
				AccountName: "some-account",
				Username:    "some-user",
				Password:    "some-pass",
				Role:        "ACCOUNTADMIN",
				Warehouse:   "some-warehouse",
			},
			expectedString: "some-user:some-pass@some-account.snowflakecomputing.com:443?database=SNOWFLAKE&ocspFailOpen=true&role=ACCOUNTADMIN&validateDefaultParameters=true&warehouse=some-warehouse",
		},
		{
			name: "Valid config with tracing enabled",
			inputConfig: Config{
				AccountName:   "some-account",
				Username:      "some-user",
				Password:      "some-pass",
				Role:          "ACCOUNTADMIN",
				Warehouse:     "some-warehouse",
				EnableTracing: true,
			},
			expectedString: "some-user:some-pass@some-account.snowflakecomputing.com:443?database=SNOWFLAKE&ocspFailOpen=true&role=ACCOUNTADMIN&tracing=trace&validateDefaultParameters=true&warehouse=some-warehouse",
		},
		{
			name: "Valid config with tracing disabled (same as default valid config)",
			inputConfig: Config{
				AccountName:   "some-account",
				Username:      "some-user",
				Password:      "some-pass",
				Role:          "ACCOUNTADMIN",
				Warehouse:     "some-warehouse",
				EnableTracing: false,
			},
			expectedString: "some-user:some-pass@some-account.snowflakecomputing.com:443?database=SNOWFLAKE&ocspFailOpen=true&role=ACCOUNTADMIN&validateDefaultParameters=true&warehouse=some-warehouse",
		},
		{
			name: "Connection string parts are escaped",
			inputConfig: Config{
				AccountName: "some%account",
				Username:    "some%user",
				Password:    "some pass",
				Role:        "ACCOUNTADMIN!",
				Warehouse:   "some!warehouse",
			},
			expectedString: `some%25user:some+pass@some%account.snowflakecomputing.com:443?database=SNOWFLAKE&ocspFailOpen=true&role=ACCOUNTADMIN%21&validateDefaultParameters=true&warehouse=some%21warehouse`,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			connStr, err := tc.inputConfig.snowflakeConnectionString()
			require.Nil(t, err)
			require.Equal(t, tc.expectedString, connStr)
		})
	}
}
