#!/bin/bash

## Install Docker https://docs.docker.com/engine/install/ubuntu

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

## Set environment variables

export NEW_RELIC_API_KEY=
export NEW_RELIC_OTLP_ENDPOINT=https://otlp.nr-data.net

## Install New Relic Infrastructure Agent https://docs.newrelic.com/docs/infrastructure/infrastructure-agent/linux-installation/package-manager-install/

echo "license_key: ${NEW_RELIC_API_KEY}" | sudo tee -a /etc/newrelic-infra.yml
curl -fsSL https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/newrelic-infra.gpg
echo "deb https://download.newrelic.com/infrastructure_agent/linux/apt jammy main" | sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list
sudo apt-get update
sudo apt-get install newrelic-infra -y

## Create docker-compose.yml

cat > /root/docker-compose.yml <<- EOF
services:
  otelcol:
    image: otel/opentelemetry-collector-contrib:0.117.0
    volumes:
      - /root/otel-config.yml:/otel-config.yml
    command: ["--config=/otel-config.yml"]
    environment:
      - NEW_RELIC_API_KEY
      - NEW_RELIC_OTLP_ENDPOINT
  adservice:
    image: otel/demo:1.10.0-adservice
    environment:
      - AD_SERVICE_PORT=8080
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4318
      - OTEL_SERVICE_NAME=adservice

EOF

## Create otel-config.yml

cat > /root/otel-config.yml <<- EOF
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
  resourcedetection:
    detectors: ["azure"]

exporters:
  otlphttp:
    endpoint: ${NEW_RELIC_OTLP_ENDPOINT}
    headers:
      api-key: ${NEW_RELIC_API_KEY}

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [resourcedetection, batch]
      exporters: [otlphttp]
    metrics:
      receivers: [otlp]
      processors: [resourcedetection, batch]
      exporters: [otlphttp]
    logs:
      receivers: [otlp]
      processors: [resourcedetection, batch]
      exporters: [otlphttp]

EOF

# Start services

docker compose -f /root/docker-compose.yml up -d
