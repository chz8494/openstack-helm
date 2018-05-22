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

{{- define "helm-toolkit.scripts.rabbit_init" }}
#!/bin/bash
set -e
# Extract connection details
RABBIT_HOSTNAME=$(echo "${RABBITMQ_ADMIN_CONNECTION}" | \
  awk -F'[@]' '{print $2}' | \
  awk -F'[:/]' '{print $1}')
RABBIT_PORT=$(echo "${RABBITMQ_ADMIN_CONNECTION}" | \
  awk -F'[@]' '{print $2}' | \
  awk -F'[:/]' '{print $2}')

# Extract Admin User creadential
RABBITMQ_ADMIN_USERNAME=$(echo "${RABBITMQ_ADMIN_CONNECTION}" | \
  awk -F'[@]' '{print $1}' | \
  awk -F'[//:]' '{print $4}')
RABBITMQ_ADMIN_PASSWORD=$(echo "${RABBITMQ_ADMIN_CONNECTION}" | \
  awk -F'[@]' '{print $1}' | \
  awk -F'[//:]' '{print $5}')

# Extract User creadential
RABBITMQ_USERNAME=$(echo "${RABBITMQ_USER_CONNECTION}" | \
  awk -F'[@]' '{print $1}' | \
  awk -F'[//:]' '{print $4}')
RABBITMQ_PASSWORD=$(echo "${RABBITMQ_USER_CONNECTION}" | \
  awk -F'[@]' '{print $1}' | \
  awk -F'[//:]' '{print $5}')

# Extract User vHost
RABBITMQ_VHOST=$(echo "${RABBITMQ_USER_CONNECTION}" | \
  awk -F'[@]' '{print $2}' | \
  awk -F'[:/]' '{print $3}')

function rabbitmqadmin_cli () {
  rabbitmqadmin \
    --host="${RABBIT_HOSTNAME}" \
    --port="${RABBIT_PORT}" \
    --username="${RABBITMQ_ADMIN_USERNAME}" \
    --password="${RABBITMQ_ADMIN_PASSWORD}" \
    ${@}
}

echo "Managing: User: ${RABBITMQ_USERNAME}"
rabbitmqadmin_cli \
  declare user \
  name="${RABBITMQ_USERNAME}" \
  password="${RABBITMQ_PASSWORD}" \
  tags="user"

echo "Managing: vHost: ${RABBITMQ_VHOST}"
rabbitmqadmin_cli \
  declare vhost \
  name="${RABBITMQ_VHOST}"

echo "Managing: Permissions: ${RABBITMQ_USERNAME} on ${RABBITMQ_VHOST}"
rabbitmqadmin_cli \
  declare permission \
  vhost="${RABBITMQ_VHOST}" \
  user="${RABBITMQ_USERNAME}" \
  configure=".*" \
  write=".*" \
  read=".*"
{{- end }}
