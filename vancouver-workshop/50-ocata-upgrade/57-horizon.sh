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

set -x
for JOBS in $(kubectl get jobs -n openstack | grep horizon | awk '{print $1}'); do
  kubectl delete job $JOBS -n openstack;
done

set -xe
WORK_DIR=/opt/openstack-helm
VALUES_DIR=/opt/vancouver-workshop/50-ocata-upgrade/override-files

helm upgrade horizon ${WORK_DIR}/horizon \
    -f ${VALUES_DIR}/horizon-ocata.yaml \
    --set network.node_port.enabled=true \
    --set network.node_port.port=31000 \

#NOTE: Wait for deploy
bash /opt/vancouver-workshop/90-common/wait-for-pods.sh openstack

#NOTE: Validate Deployment info
helm status horizon
