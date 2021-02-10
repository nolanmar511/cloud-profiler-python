#!/bin/bash

PROJECT_ID="glassy-azimuth-303722"

# Fail on any error.
set -eo pipefail

# Display commands being run
set -x

# Enable serial port logging; only needs to be done once.
gcloud compute project-info add-metadata \
    --metadata serial-port-logging-enable=true \
    --project="$PROJECT_ID"

gcloud compute instances create run-python-bench2 \
  --metadata-from-file startup-script=start_bench.sh \
  --project="$PROJECT_ID" \
  --zone=us-central1-a \
  --image-family="ubuntu-1804-lts" \
  --image-project="ubuntu-os-cloud" \
  --machine-type="n1-standard-1" 

# Check VMs serial port logs in GCP.