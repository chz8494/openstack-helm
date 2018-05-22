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

# This function defines commands, hosts, hostgroups, and services for nagios by
# consuming yaml trees to define the fields for these objects

{{- define "nagios.object_definition" -}}
{{- $type := index . 0 }}
{{- $objects := index . 1 }}
{{- range $object := $objects }}
{{ range $config := $object }}
define {{ $type }} {
{{- range $key, $value := $config}}
  {{ $key }} {{ $value }}
{{- end }}
}
{{end -}}
{{- end -}}
{{- end -}}

{{- define "nagios.to_nagios_conf" -}}
{{- range $key, $value := . -}}
{{ if eq $key "cfg_file" }}
{{ range $file := $value -}}
{{ $key }}={{ $file }}
{{ end }}
{{- else }}
{{ $key }}={{ $value }}
{{- end }}
{{- end -}}
{{- end -}}
