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

{{- define "helm-toolkit.scripts.rally_test" -}}
#!/bin/bash
set -ex
{{- $rallyTests := index . 0 }}

: "${RALLY_ENV_NAME:="openstack-helm"}"

rally-manage db create
cat > /tmp/rally-config.json << EOF
{
    "type": "ExistingCloud",
    "auth_url": "${OS_AUTH_URL}",
    "region_name": "${OS_REGION_NAME}",
    "endpoint_type": "public",
    "admin": {
        "username": "${OS_USERNAME}",
        "password": "${OS_PASSWORD}",
        "project_name": "${OS_PROJECT_NAME}",
        "user_domain_name": "${OS_USER_DOMAIN_NAME}",
        "project_domain_name": "${OS_PROJECT_DOMAIN_NAME}"
    },
    "users": [
        {
            "username": "${SERVICE_OS_USERNAME}",
            "password": "${SERVICE_OS_PASSWORD}",
            "project_name": "${SERVICE_OS_PROJECT_NAME}",
            "user_domain_name": "${SERVICE_OS_USER_DOMAIN_NAME}",
            "project_domain_name": "${SERVICE_OS_PROJECT_DOMAIN_NAME}"
        }
    ]
}
EOF
rally deployment create --file /tmp/rally-config.json --name "${RALLY_ENV_NAME}"
rm -f /tmp/rally-config.json
rally deployment use "${RALLY_ENV_NAME}"
rally deployment check
{{- if $rallyTests.run_tempest }}
rally verify create-verifier --name "${RALLY_ENV_NAME}-tempest" --type tempest
SERVICE_TYPE="$(rally deployment check | grep "${RALLY_ENV_NAME}" | awk -F \| '{print $3}' | tr -d ' ' | tr -d '\n')"
rally verify start --pattern "tempest.api.${SERVICE_TYPE}*"
rally verify delete-verifier --id "${RALLY_ENV_NAME}-tempest" --force
{{- end }}
rally task validate /etc/rally/rally_tests.yaml
rally task start /etc/rally/rally_tests.yaml
rally deployment destroy --deployment "${RALLY_ENV_NAME}"
rally task sla-check
{{- end }}
