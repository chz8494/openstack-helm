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

# This function creates a manifest for keystone user management.
# It can be used in charts dict created similar to the following:
# {- $ksUserJob := dict "envAll" . "serviceName" "senlin" }
# { $ksUserJob | include "helm-toolkit.manifests.job_ks_user" }

{{- define "helm-toolkit.manifests.job_ks_user" -}}
{{- $envAll := index . "envAll" -}}
{{- $serviceName := index . "serviceName" -}}
{{- $nodeSelector := index . "nodeSelector" | default ( dict $envAll.Values.labels.job.node_selector_key $envAll.Values.labels.job.node_selector_value ) -}}
{{- $configMapBin := index . "configMapBin" | default (printf "%s-%s" $serviceName "bin" ) -}}
{{- $serviceUser := index . "serviceUser" | default $serviceName -}}
{{- $serviceUserPretty := $serviceUser | replace "_" "-" -}}

{{- $serviceAccountName := printf "%s-%s" $serviceUserPretty "ks-user" }}
{{ tuple $envAll "ks_user" $serviceAccountName | include "helm-toolkit.snippets.kubernetes_pod_rbac_serviceaccount" }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ printf "%s-%s" $serviceUserPretty "ks-user" | quote }}
spec:
  template:
    metadata:
      labels:
{{ tuple $envAll $serviceName "ks-user" | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
    spec:
      serviceAccountName: {{ $serviceAccountName | quote }}
      restartPolicy: OnFailure
      nodeSelector:
{{ toYaml $nodeSelector | indent 8 }}
      initContainers:
{{ tuple $envAll "ks_user" list | include "helm-toolkit.snippets.kubernetes_entrypoint_init_container" | indent 8 }}
      containers:
        - name: ks-user
          image: {{ $envAll.Values.images.tags.ks_user }}
          imagePullPolicy: {{ $envAll.Values.images.pull_policy }}
{{ tuple $envAll $envAll.Values.pod.resources.jobs.ks_user | include "helm-toolkit.snippets.kubernetes_resources" | indent 10 }}
          command:
            - /tmp/ks-user.sh
          volumeMounts:
            - name: ks-user-sh
              mountPath: /tmp/ks-user.sh
              subPath: ks-user.sh
              readOnly: true
          env:
{{- with $env := dict "ksUserSecret" $envAll.Values.secrets.identity.admin }}
{{- include "helm-toolkit.snippets.keystone_openrc_env_vars" $env | indent 12 }}
{{- end }}
            - name: SERVICE_OS_SERVICE_NAME
              value: {{ $serviceName | quote }}
{{- with $env := dict "ksUserSecret" (index $envAll.Values.secrets.identity $serviceUser ) }}
{{- include "helm-toolkit.snippets.keystone_user_create_env_vars" $env | indent 12 }}
{{- end }}
            - name: SERVICE_OS_ROLES
            {{- $serviceOsRoles := index $envAll.Values.endpoints.identity.auth $serviceUser "role" }}
            {{- if kindIs "slice" $serviceOsRoles }}
              value: {{ include "helm-toolkit.utils.joinListWithComma" $serviceOsRoles | quote }}
            {{- else }}
              value: {{ $serviceOsRoles | quote }}
            {{- end }}
      volumes:
        - name: ks-user-sh
          configMap:
            name: {{ $configMapBin | quote }}
            defaultMode: 0555
{{- end -}}
