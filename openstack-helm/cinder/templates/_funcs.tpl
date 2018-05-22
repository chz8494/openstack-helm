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

{{- define "cinder.is_ceph_volume_configured" -}}
{{- range $section, $values := .Values.conf.backends -}}
{{- if kindIs "map" $values -}}
{{- if eq $values.volume_driver "cinder.volume.drivers.rbd.RBDDriver" -}}
true
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "cinder.ceph_volume_section_name" -}}
{{- range $section, $values := .Values.conf.backends -}}
{{- if kindIs "map" $values -}}
{{- if eq $values.volume_driver "cinder.volume.drivers.rbd.RBDDriver" -}}
{{ $section }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
