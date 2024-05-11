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
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"errors"
	"fmt"
	"os"

	"github.com/go-kit/log/level"
	"github.com/prometheus/common/promlog"
	sf "github.com/snowflakedb/gosnowflake"
)

type Config struct {
	AccountName        string
	Username           string
	Password           string
	Role               string
	Warehouse          string
	PrivateKeyFilePath string
}

var (
	errNoAccountName             = errors.New("account_name must be specified")
	errNoUsername                = errors.New("username must be specified")
	errNoPasswordAndNoPrivateKey = errors.New("password OR private key path must be specified")
	errNoRole                    = errors.New("role must be specified")
	errNoWarehouse               = errors.New("warehouse must be specified")
	errParsingPEM                = errors.New("failed to parse PEM block containing the private key")
	errFileNotRSAType            = errors.New("type assertion failed, expected type *rsa.PrivateKey")
)

func (c Config) Validate() error {
	if c.AccountName == "" {
		return errNoAccountName
	}

	if c.Username == "" {
		return errNoUsername
	}

	// raise err if both password AND private key are not provided
	if c.Password == "" && c.PrivateKeyFilePath == "" {
		return errNoPasswordAndNoPrivateKey
	}

	if c.Role == "" {
		return errNoRole
	}

	if c.Warehouse == "" {
		return errNoWarehouse
	}

	return nil
}

// snowflakeConnectionString returns a connection string to connect to the SNOWFLAKE database using the
// options specified in the config.
// Assumes the config is valid according to Validate().
func (c Config) snowflakeConnectionString() string {
	snowflakeConfig := &sf.Config{
		Account:   c.AccountName,
		User:      c.Username,
		Password:  c.Password,
		Role:      c.Role,
		Warehouse: c.Warehouse,
		Database:  "SNOWFLAKE",
	}

	var err error
	logger := promlog.New(&promlog.Config{})

	// if private key path is provided, try parsing it
	if pkPath := c.PrivateKeyFilePath; pkPath != "" {
		snowflakeConfig.PrivateKey, err = parsePrivateKeyFromFile(pkPath)
		if err != nil {
			level.Error(logger).Log(
				"msg", fmt.Sprintf("error parsing private key file at path %s: %v", pkPath, err),
				"err", err,
			)
			os.Exit(1)
		}
		// if private key is valid, use `AuthTypeJwt` authenticator
		// https://github.com/snowflakedb/gosnowflake/blob/c355711dbd1f9ab10dfbfdcdd194656c23abb45d/doc.go#L793
		snowflakeConfig.Authenticator = sf.AuthTypeJwt
	}

	dsn, _ := sf.DSN(snowflakeConfig)

	return dsn
}

// parse private key given its file path
// https://github.com/snowflakedb/gosnowflake/blob/c355711dbd1f9ab10dfbfdcdd194656c23abb45d/dsn.go#L875
func parsePrivateKeyFromFile(path string) (*rsa.PrivateKey, error) {
	bytes, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	block, _ := pem.Decode(bytes)
	if block == nil {
		return nil, errParsingPEM
	}

	privateKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return nil, err
	}

	// assert type from `any` to `*rsa.PrivateKey`
	pk, ok := privateKey.(*rsa.PrivateKey)
	if !ok {
		return nil, fmt.Errorf("%v but got %T", errFileNotRSAType, privateKey)
	}

	return pk, nil
}
