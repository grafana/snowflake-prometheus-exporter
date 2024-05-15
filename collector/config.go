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
	"encoding/pem"
	"errors"
	"fmt"
	"os"

	"github.com/snowflakedb/gosnowflake"
	"github.com/youmark/pkcs8"
)

type Config struct {
	AccountName        string
	Username           string
	Password           string
	Role               string
	Warehouse          string
	PrivateKeyPath     string
	PrivateKeyPassword string
	PrivateKey         *rsa.PrivateKey
}

var (
	errNoAccountName = errors.New("account_name must be specified")
	errNoRole        = errors.New("role must be specified")
	errNoWarehouse   = errors.New("warehouse must be specified")
	errNoUsername    = errors.New("username must be specified")
	errNoAuth        = errors.New("password or private_key must be specified")
	errExclusiveAuth = errors.New("password and private_key are mutually exclusive and should not both be specified")
	errNoPrivKeyPwd  = errors.New("private_key needs a private_key_password to be specified")
)

func (c Config) Validate() error {
	if c.AccountName == "" {
		return errNoAccountName
	}

	if c.Username == "" {
		return errNoUsername
	}

	if c.Password == "" && c.PrivateKeyPath == "" {
		return errNoAuth
	}

	if c.Password != "" && c.PrivateKeyPath != "" {
		return errExclusiveAuth
	}

	if c.PrivateKeyPath != "" && c.PrivateKeyPassword == "" {
		return errNoPrivKeyPwd
	}

	if c.Role == "" {
		return errNoRole
	}

	if c.Warehouse == "" {
		return errNoWarehouse
	}

	return nil
}

// decryptPrivateKey returns a RSA private key from the PrivateKeyPath and PrivateKeyPassword fields
// of the config.
// Assumes that the private key is encrypted in PKCS #8 syntax, as is recommended by Snowflake
func (c Config) decryptPrivateKey() (*rsa.PrivateKey, error) {
	pk, err := os.ReadFile(c.PrivateKeyPath)
	if err != nil {
		fmt.Printf("Error opening file: %s", err)
		return nil, err
	}
	block, _ := pem.Decode(pk)

	parsedPk, err := pkcs8.ParsePKCS8PrivateKeyRSA(block.Bytes, []byte(c.PrivateKeyPassword))
	if err != nil {
		return nil, errors.New("Error occurred while parsing private key, private_key_password may be incorrect")
	}
	return parsedPk, err
}

// snowflakeConnectionString returns a connection string to connect to the SNOWFLAKE database using the
// options specified in the config.
// Assumes the config is valid according to Validate().
func (c Config) snowflakeConnectionString() (string, error) {
	sf := gosnowflake.Config{}

	sf.Account = c.AccountName
	sf.User = c.Username
	sf.Role = c.Role
	sf.Warehouse = c.Warehouse
	sf.Database = "SNOWFLAKE"

	if c.PrivateKeyPath != "" {
		// key-pair authentication
		var pk, err = c.decryptPrivateKey()
		if err != nil {
			return "", err
		}
		sf.Authenticator = gosnowflake.AuthTypeJwt
		sf.PrivateKey = pk
		dsn, err := gosnowflake.DSN(&sf)
		return dsn, err
	} else {
		// password authentication
		sf.Password = c.Password
		dsn, err := gosnowflake.DSN(&sf)
		return dsn, err
	}

}
