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

# This function creates a manifest for db creation and user management.
# It can be used in charts dict created similar to the following:
# {- $dbToDropJob := dict "envAll" . "serviceName" "senlin" -}
# { $dbToDropJob | include "helm-toolkit.manifests.job_db_drop_mysql" }
#
# If the service does not use olso then the db can be managed with:
# {- $dbToDrop := dict "inputType" "secret" "adminSecret" .Values.secrets.oslo_db.admin "userSecret" .Values.secrets.oslo_db.horizon -}
# {- $dbToDropJob := dict "envAll" . "serviceName" "horizon" "dbToDrop" $dbToDrop -}
# { $dbToDropJob | include "helm-toolkit.manifests.job_db_drop_mysql" }

{{- define "helm-toolkit.manifests.job_db_drop_mysql" -}}
{{- $envAll := index . "envAll" -}}
{{- $serviceName := index . "serviceName" -}}
{{- $nodeSelector := index . "nodeSelector" | default ( dict $envAll.Values.labels.job.node_selector_key $envAll.Values.labels.job.node_selector_value ) -}}
{{- $configMapBin := index . "configMapBin" | default (printf "%s-%s" $serviceName "bin" ) -}}
{{- $configMapEtc := index . "configMapEtc" | default (printf "%s-%s" $serviceName "etc" ) -}}
{{- $dbToDrop := index . "dbToDrop" | default ( dict "adminSecret" $envAll.Values.secrets.oslo_db.admin "configFile" (printf "/etc/%s/%s.conf" $serviceName $serviceName ) "configDbSection" "database" "configDbKey" "connection" ) -}}
{{- $dbsToDrop := default (list $dbToDrop) (index . "dbsToDrop") }}

{{- $serviceNamePretty := $serviceName | replace "_" "-" -}}

{{- $serviceAccountName := printf "%s-%s" $serviceNamePretty "db-drop" }}
{{ tuple $envAll "db_drop" $serviceAccountName | include "helm-toolkit.snippets.kubernetes_pod_rbac_serviceaccount" }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ printf "%s-%s" $serviceNamePretty "db-drop" | quote }}
  annotations:
    "helm.sh/hook": pre-delete
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    metadata:
      labels:
{{ tuple $envAll $serviceName "db-drop" | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
    spec:
      serviceAccountName: {{ $serviceAccountName }}
      restartPolicy: OnFailure
      nodeSelector:
{{ toYaml $nodeSelector | indent 8 }}
      initContainers:
{{ tuple $envAll "db_drop" list | include "helm-toolkit.snippets.kubernetes_entrypoint_init_container" | indent 8 }}
      containers:
{{- range $key1, $dbToDrop := $dbsToDrop }}
{{ $dbToDropType := default "oslo" $dbToDrop.inputType }}
        - name: {{ printf "%s-%s-%d" $serviceNamePretty "db-drop" $key1 | quote }}
          image: {{ $envAll.Values.images.tags.db_drop }}
          imagePullPolicy: {{ $envAll.Values.images.pull_policy }}
{{ tuple $envAll $envAll.Values.pod.resources.jobs.db_drop | include "helm-toolkit.snippets.kubernetes_resources" | indent 10 }}
          env:
            - name: ROOT_DB_CONNECTION
              valueFrom:
                secretKeyRef:
                  name: {{ $dbToDrop.adminSecret | quote }}
                  key: DB_CONNECTION
{{- if eq $dbToDropType "oslo" }}
            - name: OPENSTACK_CONFIG_FILE
              value: {{ $dbToDrop.configFile | quote }}
            - name: OPENSTACK_CONFIG_DB_SECTION
              value: {{ $dbToDrop.configDbSection | quote }}
            - name: OPENSTACK_CONFIG_DB_KEY
              value: {{ $dbToDrop.configDbKey | quote }}
{{- end }}
{{- if eq $dbToDropType "secret" }}
            - name: DB_CONNECTION
              valueFrom:
                secretKeyRef:
                  name: {{ $dbToDrop.userSecret | quote }}
                  key: DB_CONNECTION
{{- end }}
          command:
            - /tmp/db-drop.py
          volumeMounts:
            - name: db-drop-sh
              mountPath: /tmp/db-drop.py
              subPath: db-drop.py
              readOnly: true
{{- if eq $dbToDropType "oslo" }}
            - name: etc-service
              mountPath: {{ dir $dbToDrop.configFile | quote }}
            - name: db-drop-conf
              mountPath: {{ $dbToDrop.configFile | quote }}
              subPath: {{ base $dbToDrop.configFile | quote }}
              readOnly: true
{{- end }}
{{- end }}
      volumes:
        - name: db-drop-sh
          configMap:
            name: {{ $configMapBin | quote }}
            defaultMode: 0555
{{- $local := dict "configMapBinFirst" true -}}
{{- range $key1, $dbToDrop := $dbsToDrop }}
{{- $dbToDropType := default "oslo" $dbToDrop.inputType }}
{{- if and (eq $dbToDropType "oslo") $local.configMapBinFirst }}
{{- $_ := set $local "configMapBinFirst" false }}
        - name: etc-service
          emptyDir: {}
        - name: db-drop-conf
          configMap:
            name: {{ $configMapEtc | quote }}
            defaultMode: 0444
{{- end -}}
{{- end -}}
{{- end -}}
