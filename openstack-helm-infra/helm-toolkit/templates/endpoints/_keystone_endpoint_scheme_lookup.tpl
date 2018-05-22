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

# This function returns the scheme for a service, it takes an tuple
# input in the form: service-type, endpoint-class, port-name. eg:
# { tuple "etcd" "internal" "client" . | include "helm-toolkit.endpoints.keystone_scheme_lookup" }
# will return the scheme setting for this particular endpoint.  In other words, for most endpoints
# it will return either 'http' or 'https'

{{- define "helm-toolkit.endpoints.keystone_endpoint_scheme_lookup" -}}
{{- $type := index . 0 -}}
{{- $endpoint := index . 1 -}}
{{- $port := index . 2 -}}
{{- $context := index . 3 -}}
{{- $typeYamlSafe := $type | replace "-" "_" }}
{{- $endpointMap := index $context.Values.endpoints $typeYamlSafe }}
{{- with $endpointMap -}}
{{- $endpointScheme := index .scheme $endpoint | default .scheme.default | default "http" }}
{{- printf "%s" $endpointScheme -}}
{{- end -}}
{{- end -}}
