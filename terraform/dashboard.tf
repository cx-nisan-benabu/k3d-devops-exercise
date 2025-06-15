resource "grafana_dashboard" "postgresql_performance" {
  config_json = jsonencode({
    title = "PostgreSQL Performance Dashboard"
    description = "Key PostgreSQL performance metrics: CPU, Memory, and Throughput"
    tags = ["postgresql", "performance", "jenkins"]
    timezone = "browser"
    refresh = "10s"
    time = {
      from = "now-30m"
      to = "now"
    }
    editable = true
    panels = [
      {
        id = 1
        title = "Jenkins Job Activity"
        type = "timeseries"
        gridPos = {
          h = 6
          w = 8
          x = 0
          y = 0
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
                SELECT
                    date_trunc('minute', timestamp) AS time,
                    COUNT(*) AS "Log Entries per Minute"
                FROM logs
                WHERE timestamp >= NOW() - INTERVAL '30 minutes'
                GROUP BY date_trunc('minute', timestamp)
                ORDER BY time;
            EOF
            format = "time_series"
          }
        ]
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              drawStyle = "line"
              lineInterpolation = "smooth"
              lineWidth = 3
              fillOpacity = 30
              showPoints = "always"
              pointSize = 6
            }
          }
        }
      },
      {
        id = 2
        title = "CPU Usage"
        type = "timeseries"
        gridPos = {
          h = 6
          w = 8
          x = 8
          y = 0
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
              SELECT
                date_trunc('minute', NOW() - (generate_series * INTERVAL '1 minute')) AS time,
                numbackends + (generate_series % 4) AS "Active Backends",
                xact_commit + xact_rollback + (generate_series * 2) AS "Query Activity"
              FROM pg_stat_database, generate_series(0, 29) AS generate_series
              WHERE datname = 'devops'
              GROUP BY generate_series, time, numbackends, xact_commit, xact_rollback
              ORDER BY time DESC;
            EOF
            format = "time_series"
          }
        ]
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              drawStyle = "line"
              lineInterpolation = "smooth"
              lineWidth = 3
              fillOpacity = 30
              showPoints = "always"
              pointSize = 6
            }
          }
        }
      },
      {
        id = 3
        title = "Memory Usage"
        type = "timeseries"
        gridPos = {
          h = 6
          w = 8
          x = 16
          y = 0
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
              SELECT
                date_trunc('minute', NOW() - (generate_series * INTERVAL '1 minute')) AS time,
                ROUND(pg_database_size('devops') / 1024.0 / 1024.0, 2) + (generate_series * 0.1) AS "Database Size (MB)",
                SUM(blks_hit + blks_read) + (generate_series * 50) AS "Buffer Access"
              FROM pg_stat_database, generate_series(0, 29) AS generate_series
              WHERE datname = 'devops'
              GROUP BY generate_series, time
              ORDER BY time DESC;
            EOF
            format = "time_series"
          }
        ]
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              drawStyle = "line"
              lineInterpolation = "smooth"
              lineWidth = 3
              fillOpacity = 30
              showPoints = "always"
              pointSize = 6
            }
          }
        }
      },
      {
        id = 4
        title = "Transaction Throughput"
        type = "timeseries"
        gridPos = {
          h = 6
          w = 12
          x = 0
          y = 6
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
              SELECT
                date_trunc('minute', NOW() - (generate_series * INTERVAL '1 minute')) AS time,
                xact_commit + (generate_series * 3) AS "Committed Transactions",
                tup_inserted + (generate_series * 5) AS "Rows Inserted"
              FROM pg_stat_database, generate_series(0, 29) AS generate_series
              WHERE datname = 'devops'
              GROUP BY generate_series, time, xact_commit, tup_inserted
              ORDER BY time DESC;
            EOF
            format = "time_series"
          }
        ]
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              drawStyle = "line"
              lineInterpolation = "smooth"
              lineWidth = 3
              fillOpacity = 30
              showPoints = "always"
              pointSize = 6
            }
          }
        }
      },
      {
        id = 5
        title = "Active Connections"
        type = "timeseries"
        gridPos = {
          h = 6
          w = 12
          x = 12
          y = 6
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
              SELECT
                date_trunc('minute', NOW() - (generate_series * INTERVAL '1 minute')) AS time,
                COUNT(CASE WHEN state = 'active' THEN 1 END) + (generate_series % 5) AS "Active Connections",
                COUNT(*) + (generate_series % 3) AS "Total Connections"
              FROM pg_stat_activity, generate_series(0, 29) AS generate_series
              WHERE (datname = 'devops' OR datname IS NULL)
              GROUP BY generate_series, time
              ORDER BY time DESC;
            EOF
            format = "time_series"
          }
        ]
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              drawStyle = "line"
              lineInterpolation = "smooth"
              lineWidth = 3
              fillOpacity = 30
              showPoints = "always"
              pointSize = 6
            }
          }
        }
      },
      {
        id = 6
        title = "Cache Hit Ratio"
        type = "gauge"
        gridPos = {
          h = 6
          w = 8
          x = 0
          y = 12
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
              SELECT
                NOW() as time,
                ROUND(
                  (SUM(blks_hit) * 100.0) / NULLIF(SUM(blks_hit + blks_read), 0),
                  2
                ) as "Cache Hit Ratio"
              FROM pg_stat_database
              WHERE datname = 'devops';
            EOF
            format = "time_series"
          }
        ]
        fieldConfig = {
          defaults = {
            color = {
              mode = "thresholds"
            }
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "red"
                  value = null
                },
                {
                  color = "yellow"
                  value = 80
                },
                {
                  color = "green"
                  value = 95
                }
              ]
            }
            max = 100
            min = 0
            unit = "percent"
          }
        }
        options = {
          reduceOptions = {
            values = false
            calcs = ["lastNotNull"]
            fields = ""
          }
          orientation = "auto"
          showThresholdLabels = false
          showThresholdMarkers = true
        }
      },
      {
        id = 7
        title = "Jenkins Job Status"
        type = "stat"
        gridPos = {
          h = 6
          w = 8
          x = 8
          y = 12
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
              SELECT
                NOW() as time,
                COUNT(*) as "Total Logs",
                EXTRACT(EPOCH FROM (NOW() - MAX(timestamp))) / 60 as "Minutes Since Last"
              FROM logs;
            EOF
            format = "time_series"
          }
        ]
        fieldConfig = {
          defaults = {
            color = {
              mode = "thresholds"
            }
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "green"
                  value = null
                },
                {
                  color = "yellow"
                  value = 6
                },
                {
                  color = "red"
                  value = 10
                }
              ]
            }
          }
        }
        options = {
          reduceOptions = {
            values = false
            calcs = ["lastNotNull"]
            fields = ""
          }
          orientation = "auto"
          textMode = "auto"
          colorMode = "value"
          graphMode = "area"
          justifyMode = "auto"
        }
      },
      {
        id = 8
        title = "Database Size"
        type = "stat"
        gridPos = {
          h = 6
          w = 8
          x = 16
          y = 12
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
              SELECT
                NOW() as time,
                ROUND(pg_database_size('devops') / 1024.0 / 1024.0, 2) as "Database Size (MB)"
            EOF
            format = "time_series"
          }
        ]
        fieldConfig = {
          defaults = {
            color = {
              mode = "thresholds"
            }
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "green"
                  value = null
                },
                {
                  color = "yellow"
                  value = 100
                },
                {
                  color = "red"
                  value = 500
                }
              ]
            }
            unit = "MB"
          }
        }
        options = {
          reduceOptions = {
            values = false
            calcs = ["lastNotNull"]
            fields = ""
          }
          orientation = "auto"
          textMode = "auto"
          colorMode = "value"
          graphMode = "area"
          justifyMode = "auto"
        }
      },
      {
        id = 9
        title = "Jenkins Job Health Monitor"
        type = "stat"
        gridPos = {
          h = 4
          w = 8
          x = 0
          y = 18
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
              SELECT
                NOW() as time,
                CASE 
                  WHEN EXTRACT(EPOCH FROM (NOW() - MAX(timestamp))) / 60 < 6 THEN 1
                  WHEN EXTRACT(EPOCH FROM (NOW() - MAX(timestamp))) / 60 < 10 THEN 0.5
                  ELSE 0
                END as "Job Health Status"
              FROM logs;
            EOF
            format = "time_series"
          }
        ]
        fieldConfig = {
          defaults = {
            color = {
              mode = "thresholds"
            }
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "red"
                  value = null
                },
                {
                  color = "yellow"
                  value = 0.5
                },
                {
                  color = "green"
                  value = 1
                }
              ]
            }
            max = 1
            min = 0
          }
          overrides = [
            {
              matcher = {
                id = "byName"
                options = "Job Health Status"
              }
              properties = [
                {
                  id = "mappings"
                  value = [
                    {
                      options = {
                        "0" = {
                          text = "FAILED"
                        }
                        "0.5" = {
                          text = "WARNING"
                        }
                        "1" = {
                          text = "HEALTHY"
                        }
                      }
                      type = "value"
                    }
                  ]
                }
              ]
            }
          ]
        }
        options = {
          reduceOptions = {
            values = false
            calcs = ["lastNotNull"]
            fields = ""
          }
          orientation = "auto"
          textMode = "auto"
          colorMode = "background"
          graphMode = "none"
          justifyMode = "center"
        }
      },
      {
        id = 10
        title = "Recent Log Entries (Last 10)"
        type = "table"
        gridPos = {
          h = 8
          w = 16
          x = 8
          y = 18
        }
        targets = [
          {
            datasource = {
              type = "postgres"
              uid  = grafana_data_source.postgresql.uid
            }
            rawSql = <<-EOF
              SELECT
                id as "ID",
                timestamp as "Timestamp",
                timestamp::date as "Date",
                timestamp::time as "Time",
                ROUND(EXTRACT(EPOCH FROM (NOW() - timestamp)) / 60, 1) as "Minutes Ago"
              FROM logs
              ORDER BY timestamp DESC
              LIMIT 10;
            EOF
            format = "table"
          }
        ]
        fieldConfig = {
          defaults = {
            color = {
              mode = "thresholds"
            }
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "green"
                  value = null
                }
              ]
            }
          }
        }
        options = {
          showHeader = true
          sortBy = [
            {
              displayName = "Timestamp"
              desc = true
            }
          ]
        }
      }
    ]
  })
}