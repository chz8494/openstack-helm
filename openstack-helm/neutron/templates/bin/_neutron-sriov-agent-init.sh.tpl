#!/bin/bash

{{/*
Copyright 2017 The Openstack-Helm Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}

set -ex

{{- range $k, $sriov := .Values.network.interface.sriov }}
if [ "x{{ $sriov.num_vfs }}" != "x" ]; then
  echo "{{ $sriov.num_vfs }}" > /sys/class/net/{{ $sriov.device }}/device/sriov_numvfs
else
  NUM_VFS=$(cat /sys/class/net/{{ $sriov.device }}/device/sriov_totalvfs)
  echo "${NUM_VFS}" > /sys/class/net/{{ $sriov.device }}/device/sriov_numvfs
fi
ip link set {{ $sriov.device }} up
ip link show {{ $sriov.device }}
{{- if $sriov.promisc }}
ip link set {{ $sriov.device }} promisc on
#NOTE(portdirect): get the bus that the port is on
NIC_BUS=$(lshw -c network -businfo | awk '/{{ $sriov.device }}/ {print $1}')
#NOTE(portdirect): get first port on the nic
NIC_FIRST_PORT=$(lshw -c network -businfo | awk "/${NIC_BUS%%.*}/ { print \$2; exit }"
#NOTE(portdirect): Enable promisc mode on the nic, by setting it for the 1st port
ethtool --set-priv-flags ${NIC_FIRST_PORT} vf-true-promisc-support on
{{- end }}
{{- end }}
