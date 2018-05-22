#!/bin/bash

# Copyright 2017 The Openstack-Helm Authors.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

set -xe

#NOTE: Lint and package chart
make prometheus-openstack-exporter

#NOTE: Deploy command
tee /tmp/prometheus-openstack-exporter.yaml << EOF
manifests:
  job_ks_user: false
dependencies:
  static:
    prometheus_openstack_exporter:
      jobs: null
      services: null
EOF
helm upgrade --install prometheus-openstack-exporter \
    ./prometheus-openstack-exporter \
    --namespace=openstack \
    --values=/tmp/prometheus-openstack-exporter.yaml

#NOTE: Wait for deploy
./tools/deployment/common/wait-for-pods.sh openstack

#NOTE: Validate Deployment info
helm status prometheus-openstack-exporter
