# New Relic Infra Agent with OpenTelemetry instrumented services

## Install Terraform

```shell
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

## GCP

These steps are adapted from this
[tutorial](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build).

First modify [vm-setup.tftpl](./gcp/templates/vm-setup.tftpl) and set the
license key and OTLP endpoint.

```shell
gcloud auth application-default login
cd gcp
terraform init
terraform apply
gcloud compute ssh --zone "us-central1-a" "apm-infra-gcp-vm" --project "opentracing-265818"
terraform destroy
```
