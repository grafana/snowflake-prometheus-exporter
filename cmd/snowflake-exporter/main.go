// Copyright 2022 Grafana Labs
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

package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/go-kit/log"
	"github.com/go-kit/log/level"
	"github.com/grafana/snowflake-prometheus-exporter/collector"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/prometheus/common/promlog"
	"github.com/prometheus/common/promlog/flag"
	"github.com/prometheus/common/version"
	"github.com/prometheus/exporter-toolkit/web"
	webflag "github.com/prometheus/exporter-toolkit/web/kingpinflag"
	"gopkg.in/alecthomas/kingpin.v2"
)

var (
	webConfig          = webflag.AddFlags(kingpin.CommandLine, ":9975")
	metricPath         = kingpin.Flag("web.telemetry-path", "Path under which to expose metrics.").Default("/metrics").Envar("SNOWFLAKE_EXPORTER_WEB_TELEMETRY_PATH").String()
	account            = kingpin.Flag("account", "The account to collect metrics for.").Envar("SNOWFLAKE_EXPORTER_ACCOUNT").Required().String()
	username           = kingpin.Flag("username", "The username for the user used when querying metrics.").Envar("SNOWFLAKE_EXPORTER_USERNAME").Required().String()
	password           = kingpin.Flag("password", "The password for the user used when querying metrics.").Envar("SNOWFLAKE_EXPORTER_PASSWORD").String()
	privateKeyPath     = kingpin.Flag("private-key-path", "The path to the user's RSA private key").Envar("SNOWFLAKE_EXPORTER_PRIVATE_KEY_PATH").String()
	privateKeyPassword = kingpin.Flag("private-key-password", "The password for the user's RSA private key.").Envar("SNOWFLAKE_EXPORTER_PRIVATE_KEY_PASSWORD").String()
	role               = kingpin.Flag("role", "The role to use when querying metrics.").Default("ACCOUNTADMIN").Envar("SNOWFLAKE_EXPORTER_ROLE").String()
	warehouse          = kingpin.Flag("warehouse", "The warehouse to use when querying metrics.").Envar("SNOWFLAKE_EXPORTER_WAREHOUSE").Required().String()
	excludeDeleted     = kingpin.Flag("exclude-deleted-tables", "Exclude deleted tables when collecting table storage metrics.").Default("false").Bool()
	enableTracing      = kingpin.Flag("enable-tracing", "Enable trace logging for Snowflake connections.").Default("false").Envar("SNOWFLAKE_EXPORTER_ENABLE_TRACING").Bool()
)

const (
	// The name of the exporter.
	exporterName    = "snowflake_exporter"
	landingPageHtml = `<html>
<head><title>Snowflake exporter</title></head>
	<body>
		<h1>Snowflake exporter</h1>
		<p><a href='%s'>Metrics</a></p>
	</body>
</html>`
)

func main() {
	kingpin.Version(version.Print(exporterName))

	promlogConfig := &promlog.Config{}

	flag.AddFlags(kingpin.CommandLine, promlogConfig)
	kingpin.HelpFlag.Short('h')
	kingpin.Parse()

	logger := promlog.New(promlogConfig)

	// Construct the collector, using the flags for configuration
	c := &collector.Config{
		AccountName:        *account,
		Username:           *username,
		Password:           *password,
		PrivateKeyPath:     *privateKeyPath,
		PrivateKeyPassword: *privateKeyPassword,
		Role:               *role,
		Warehouse:          *warehouse,
		ExcludeDeleted:     *excludeDeleted,
		EnableTracing:      *enableTracing,
	}

	if err := c.Validate(); err != nil {
		level.Error(logger).Log("msg", "Configuration is invalid.", "err", err)
		os.Exit(1)
	}

	col := collector.NewCollector(logger, c)

	// Register collector with prometheus client library
	prometheus.MustRegister(version.NewCollector(exporterName))
	prometheus.MustRegister(col)

	serveMetrics(logger)
}

func serveMetrics(logger log.Logger) {
	landingPage := []byte(fmt.Sprintf(landingPageHtml, *metricPath))

	http.Handle(*metricPath, promhttp.Handler())
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=UTF-8") // nolint: errcheck
		w.Write(landingPage)                                       // nolint: errcheck
	})

	srv := &http.Server{}
	if err := web.ListenAndServe(srv, webConfig, logger); err != nil {
		level.Error(logger).Log("msg", "Error running HTTP server", "err", err)
		os.Exit(1)
	}
}
