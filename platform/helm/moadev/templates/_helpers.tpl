{{- define "moadev.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "moadev.fullname" -}}
{{- if .Values.global.fullnameOverride -}}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "moadev.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "moadev.componentFullname" -}}
{{- printf "%s-%s" (include "moadev.fullname" .root) .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "moadev.selectorLabels" -}}
app.kubernetes.io/name: {{ include "moadev.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "moadev.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .root.Chart.Name (.root.Chart.Version | replace "+" "_") }}
{{ include "moadev.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- $globalLabels := .root.Values.global.labels | default dict -}}
{{- $valuesKey := .valuesKey | default .component -}}
{{- $componentValues := get .root.Values $valuesKey | default dict -}}
{{- $componentLabels := $componentValues.labels | default dict -}}
{{- $labels := merge (deepCopy $globalLabels) $componentLabels -}}
{{- range $key := keys $labels | sortAlpha }}
{{ $key }}: {{ index $labels $key | quote }}
{{- end }}
{{- end -}}

{{- define "moadev.image" -}}
{{- $registry := .componentValues.image.registry | default .root.Values.global.imageRegistry -}}
{{- $tag := .componentValues.image.tag | default .root.Values.global.imageTag -}}
{{- printf "%s/%s:%s" $registry .componentValues.image.repository $tag -}}
{{- end -}}

{{- define "moadev.secretName" -}}
{{- if .componentValues.existingSecretName -}}
{{- .componentValues.existingSecretName -}}
{{- else -}}
{{- include "moadev.componentFullname" (dict "root" .root "component" .component) -}}
{{- end -}}
{{- end -}}

{{- define "moadev.renderEnv" -}}
{{- $component := .componentValues -}}
{{- $excludeKeys := .excludeKeys | default (list) -}}
{{- if $component.env }}
{{- range $name := keys $component.env | sortAlpha }}
{{- if not (has $name $excludeKeys) }}
- name: {{ $name }}
  value: {{ index $component.env $name | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- if $component.secretEnv }}
{{- $secretName := include "moadev.secretName" . -}}
{{- range $name := keys $component.secretEnv | sortAlpha }}
- name: {{ $name }}
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ index $component.secretEnv $name }}
{{- end }}
{{- end }}
{{- end -}}
