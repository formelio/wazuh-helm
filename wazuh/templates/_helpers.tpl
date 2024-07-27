{{/*
Expand the name of the chart.
*/}}
{{- define "wazuh.name" -}}
{{- default "wazuh" .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wazuh.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "wazuh" .Values.nameOverride }}
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
{{- define "wazuh.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wazuh.labels" -}}
helm.sh/chart: {{ include "wazuh.chart" . }}
{{ include "wazuh.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wazuh.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wazuh.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wazuh.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wazuh.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "wazuh.dn" -}}
{{- $subj := .Values.global.certificateSubject }}
{{- $parts := list }}
{{- with $subj.country }}{{ $parts = append $parts (printf "C=%v" . )}}{{ end }}
{{- with $subj.locality }}{{ $parts = append $parts (printf "L=%v" . )}}{{ end }}
{{- with $subj.organization }}{{ $parts = append $parts (printf "O=%v" . )}}{{ end }}
{{- $parts = append $parts (printf "CN=%v" .cn ) }}
{{- join "," $parts }}
{{- end }}

{{- define "wazuh.ca" -}}
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: {{ include "wazuh.fullname" . }}-self-signer
  labels: {{ include "wazuh.labels" . | nindent 4 }}
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: {{ include "wazuh.fullname" . }}-ca-cert
  labels: {{ include "wazuh.labels" . | nindent 4 }}
spec:
  secretName: "{{ include "wazuh.fullname" . }}-ca-cert"

  secretTemplate:
    labels: {{ include "wazuh.labels" . | nindent 6 }}

  isCA: true

  commonName: "{{ include "wazuh.fullname" . }}-ca"

  {{- with .Values.global.certificateSubject }}
  subject:
    organizations: [{{ .organization }}]
    countries: [{{ .country }}]
    localities: [{{ .locality }}]
  {{- end }}

  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048

  # Valid for 20 years
  duration: 175316h

  issuerRef:
    name: {{ include "wazuh.fullname" . }}-self-signer
    kind: Issuer
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: "{{ include "wazuh.fullname" . }}-ca"
  labels: {{ include "wazuh.labels" . | nindent 4 }}
spec:
  ca:
    secretName: "{{ include "wazuh.fullname" . }}-ca-cert"
{{- end }}

