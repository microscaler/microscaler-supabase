{{- define "microscaler-supabase.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "microscaler-supabase.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "microscaler-supabase.namespace" -}}
{{- .Release.Namespace -}}
{{- end }}

{{- define "microscaler-supabase.labels" -}}
helm.sh/chart: {{ include "microscaler-supabase.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/name: {{ include "microscaler-supabase.name" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{- define "microscaler-supabase.infraSecretName" -}}
{{- if .Values.secret.create -}}
{{- .Values.secret.name -}}
{{- else -}}
{{- required "secret.existingSecret is required when secret.create is false" .Values.secret.existingSecret -}}
{{- end -}}
{{- end }}

{{- define "microscaler-supabase.postgresPvcName" -}}
{{- if eq .Values.persistence.mode "existingClaim" -}}
{{- required "persistence.existingClaim.postgres is required when persistence.mode=existingClaim" .Values.persistence.existingClaim.postgres -}}
{{- else -}}
{{- .Values.persistence.postgres.pvcName -}}
{{- end -}}
{{- end }}

{{- define "microscaler-supabase.parquetPvcName" -}}
{{- if eq .Values.persistence.mode "existingClaim" -}}
{{- .Values.persistence.existingClaim.parquet -}}
{{- else -}}
{{- .Values.persistence.parquet.pvcName -}}
{{- end -}}
{{- end }}

{{- define "microscaler-supabase.initRolePassword" -}}
{{- if .Values.secret.create -}}
{{- default .Values.secret.data.POSTGRES_PASSWORD .Values.postgres.initPasswords.default -}}
{{- else -}}
{{- required "postgres.initPasswords.default is required when secret.existingSecret is set" .Values.postgres.initPasswords.default -}}
{{- end -}}
{{- end }}

{{- define "microscaler-supabase.jwtSecret" -}}
{{- default "your-super-secret-jwt-token-with-at-least-32-characters-long" .Values.postgres.initSql.jwtSecret -}}
{{- end }}

{{- define "microscaler-supabase.postgresExporterUri" -}}
{{- $u := default .Values.secret.data.POSTGRES_USER .Values.postgresExporter.connection.user -}}
{{- $pw := default .Values.secret.data.POSTGRES_PASSWORD .Values.postgresExporter.connection.password -}}
{{- $db := .Values.infraConfig.data.POSTGRES_DB -}}
{{- $host := default "postgres" .Values.postgresExporter.connection.host -}}
{{- $port := default "5432" .Values.postgresExporter.connection.port -}}
{{- printf "postgresql://%s:%s@%s:%s/%s?sslmode=disable" $u $pw $host $port $db -}}
{{- end }}
