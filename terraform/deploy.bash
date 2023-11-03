#!/bin/bash

cd infra
terraform init
terraform validate
terraform apply -auto-approve

cd ../app
terraform init
terraform validate
terraform apply -auto-approve