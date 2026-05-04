# Grafana Datasources Provisioning

This directory contains datasource provisioning files that Grafana loads automatically on startup.

## Files

| File             | Description                                         |
|------------------|-----------------------------------------------------|
| `prometheus.yml` | Configures Prometheus as the default datasource     |

## How it works

Grafana reads all `.yml` files in this directory when it starts. The `prometheus.yml` file instructs Grafana to add a Prometheus datasource pointing to `http://prometheus:9090` (the Prometheus container on the internal Docker network).

The datasource is set as **default** and **non-editable** to prevent accidental misconfiguration.

## Adding more datasources

Create additional `.yml` files in this directory following the [Grafana datasource provisioning format](https://grafana.com/docs/grafana/latest/administration/provisioning/#datasources).
