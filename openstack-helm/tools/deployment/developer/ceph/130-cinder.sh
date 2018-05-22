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
make cinder

#NOTE: Deploy command
: ${OSH_EXTRA_HELM_ARGS:=""}
tee /tmp/cinder.yaml <<EOF
conf:
  ceph:
    pools:
      backup:
        replication: 1
        crush_rule: same_host
        chunk_size: 8
      volume:
        replication: 1
        crush_rule: same_host
        chunk_size: 8
EOF
helm upgrade --install cinder ./cinder \
  --namespace=openstack \
  --values=/tmp/cinder.yaml \
  ${OSH_EXTRA_HELM_ARGS} \
  ${OSH_EXTRA_HELM_ARGS_CINDER}

#NOTE: Wait for deploy
./tools/deployment/common/wait-for-pods.sh openstack

#NOTE: Validate Deployment info
export OS_CLOUD=openstack_helm
openstack service list
sleep 30 #NOTE(portdirect): Wait for ingress controller to update rules and restart Nginx
openstack volume type list
