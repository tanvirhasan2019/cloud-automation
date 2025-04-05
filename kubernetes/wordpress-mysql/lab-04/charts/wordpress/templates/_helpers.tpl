{{/*
Expand the name of the chart.
*/}}
{{- define "wordpress.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wordpress.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wordpress.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wordpress.labels" -}}
helm.sh/chart: {{ include "wordpress.chart" . }}
{{ include "wordpress.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wordpress.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wordpress.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wordpress.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wordpress.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name for the MySQL dependency.
*/}}
{{- define "wordpress.mysql.fullname" -}}
{{- if .Values.mysql.fullnameOverride -}}
{{- .Values.mysql.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "mysql" .Values.mysql.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the MySQL host name
*/}}
{{- define "wordpress.mysql.host" -}}
{{- if .Values.mysql.enabled -}}
{{- include "wordpress.mysql.fullname" . -}}
{{- else -}}
{{- .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
Create the MySQL port
*/}}
{{- define "wordpress.mysql.port" -}}
{{- if .Values.mysql.enabled -}}
{{- printf "%d" (int .Values.mysql.primary.service.port) -}}
{{- else -}}
{{- printf "%d" (int .Values.externalDatabase.port) -}}
{{- end -}}
{{- end -}}

{{/*
Create the MySQL database name
*/}}
{{- define "wordpress.mysql.database" -}}
{{- if .Values.mysql.enabled -}}
{{- .Values.mysql.auth.database -}}
{{- else -}}
{{- .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
Create the MySQL user
*/}}
{{- define "wordpress.mysql.username" -}}
{{- if .Values.mysql.enabled -}}
{{- .Values.mysql.auth.username -}}
{{- else -}}
{{- .Values.externalDatabase.user -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified Redis name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "wordpress.cache.host" -}}
{{- if .Values.redis.enabled -}}
{{- if .Values.redis.architecture -}}
{{- if eq .Values.redis.architecture "replication" -}}
{{- printf "%s-master" (include "common.names.fullname" .Subcharts.redis) | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "common.names.fullname" .Subcharts.redis | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- else -}}
{{- include "common.names.fullname" .Subcharts.redis | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- else -}}
{{- .Values.redis.hostname | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis hostname
*/}}
{{- define "wordpress.cache.port" -}}
{{- if .Values.redis.enabled -}}
{{- .Values.redis.master.service.ports.redis | default 6379 -}}
{{- else -}}
{{- .Values.redis.port | default 6379 -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis secret name
*/}}
{{- define "wordpress.cache.secretName" -}}
{{- if .Values.redis.enabled -}}
{{- if .Values.redis.auth.existingSecret -}}
{{- .Values.redis.auth.existingSecret | quote -}}
{{- else -}}
{{- printf "%s" (include "common.names.fullname" .Subcharts.redis) -}}
{{- end -}}
{{- else if .Values.redis.existingSecret -}}
{{- .Values.redis.existingSecret | quote -}}
{{- else -}}
{{- printf "%s-redis" (include "wordpress.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the WordPress secret name
*/}}
{{- define "wordpress.secretName" -}}
{{- if .Values.existingSecret -}}
{{- .Values.existingSecret -}}
{{- else -}}
{{- include "wordpress.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the host to be used by WordPress
*/}}
{{- define "wordpress.httpHost" -}}
{{- if .Values.ingress.enabled -}}
{{- $host := (index .Values.ingress.hosts 0).name | default "" -}}
{{- printf "%s" $host -}}
{{- else -}}
{{- printf "%s" (include "wordpress.fullname" .) -}}
{{- end -}}
{{- end -}}