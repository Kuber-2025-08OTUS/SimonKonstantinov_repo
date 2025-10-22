{{- define "homework-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "homework-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "homework-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end }}

{{- define "homework-app.labels" -}}
helm.sh/chart: {{ include "homework-app.chart" . }}
{{ include "homework-app.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "homework-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "homework-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "homework-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "homework-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- "default" }}
{{- end }}
{{- end }}
