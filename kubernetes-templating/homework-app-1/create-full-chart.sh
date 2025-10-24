#!/bin/bash
set -e

echo "========================================="
echo "Создание полного Helm Chart"
echo "========================================="

# Удаляем стандартные файлы если есть
rm -f templates/*.yaml templates/NOTES.txt 2>/dev/null || true
rm -rf templates/tests 2>/dev/null || true

# Chart.yaml
cat > Chart.yaml <<'EOF'
apiVersion: v2
name: homework-app
description: Helm chart for homework application with nginx, metrics, and Redis
type: application
version: 1.0.0
appVersion: "1.0.0"

dependencies:
  - name: redis
    version: "19.0.0"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
EOF

# values.yaml
cat > values.yaml <<'EOF'
# Базовые настройки
nameOverride: ""
fullnameOverride: ""
namespace: homework

# Количество реплик
replicaCount: 3

# Образ приложения (разделены repository и tag)
image:
  repository: nginx
  tag: alpine
  pullPolicy: IfNotPresent

# ServiceAccount
serviceAccount:
  create: true
  name: monitoring

# Service
service:
  type: ClusterIP
  port: 80
  targetPort: 80

# NodeSelector
nodeSelector:
  homework: "true"

# Readiness и Liveness probes (можно включать/выключать)
probes:
  readiness:
    enabled: true
    path: /index.html
    port: 80
    initialDelaySeconds: 5
    periodSeconds: 10
  liveness:
    enabled: false
    path: /
    port: 80

# Lifecycle hooks
lifecycle:
  preStop:
    enabled: true
    command: ['sh', '-c', 'rm -f /usr/share/nginx/html/index.html']

# ConfigMap
configMap:
  enabled: true
  data:
    app.conf: |
      app.name=Homework App
      app.version=1.0.0
      environment=production
    database.conf: |
      db.host=localhost
      db.port=5432
      db.name=homework

# Persistence
persistence:
  enabled: true
  storageClassName: homework-storage
  accessMode: ReadWriteOnce
  size: 1Gi

# StorageClass
storageClass:
  enabled: true
  name: homework-storage
  provisioner: k8s.io/minikube-hostpath
  reclaimPolicy: Retain
  volumeBindingMode: Immediate

# InitContainers
initContainers:
  downloadIndex:
    enabled: true
    image:
      repository: busybox
      tag: latest
    command: ['sh', '-c', 'wget -O /init/index.html https://raw.githubusercontent.com/kubernetes/website/main/content/en/index.html || echo "Hello from Homework!" > /init/index.html']
  
  fetchMetrics:
    enabled: true
    image:
      repository: curlimages/curl
      tag: "8.8.0"
    command:
      - sh
      - -c
      - |
        set -e
        CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
        curl --fail --retry 5 --retry-delay 2 \
             --cacert $CA \
             -H "Authorization: Bearer $TOKEN" \
             https://kubernetes.default.svc/metrics \
             | sed '1i <pre>' \
             | sed '$a </pre>' > /init/metrics.html

# Стратегия обновления
strategy:
  type: RollingUpdate
  maxUnavailable: 1

# RBAC для метрик
rbac:
  create: true
  clusterRole:
    name: monitoring-metrics-read
    rules:
      - apiGroups: [""]
        resources: ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
        verbs: ["get", "list", "watch"]
      - nonResourceURLs: ["/metrics", "/metrics/*"]
        verbs: ["get"]

# Redis dependency (community chart)
redis:
  enabled: true
  auth:
    enabled: false
  master:
    persistence:
      enabled: false
  replica:
    replicaCount: 1
    persistence:
      enabled: false
EOF

echo "✓ Chart.yaml и values.yaml созданы"

# templates/_helpers.tpl
mkdir -p templates
cat > templates/_helpers.tpl <<'EOF'
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
EOF

# templates/namespace.yaml
cat > templates/namespace.yaml <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: {{ .Values.namespace }}
  labels:
    {{- include "homework-app.labels" . | nindent 4 }}
EOF

# templates/serviceaccount.yaml
cat > templates/serviceaccount.yaml <<'EOF'
{{- if .Values.serviceAccount.create }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "homework-app.serviceAccountName" . }}
  namespace: {{ .Values.namespace }}
  labels:
    {{- include "homework-app.labels" . | nindent 4 }}
{{- end }}
EOF

# templates/rbac.yaml
cat > templates/rbac.yaml <<'EOF'
{{- if .Values.rbac.create }}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ include "homework-app.fullname" . }}-{{ .Values.rbac.clusterRole.name }}
  labels:
    {{- include "homework-app.labels" . | nindent 4 }}
rules:
{{- toYaml .Values.rbac.clusterRole.rules | nindent 2 }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ include "homework-app.fullname" . }}-metrics-binding
  labels:
    {{- include "homework-app.labels" . | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ include "homework-app.fullname" . }}-{{ .Values.rbac.clusterRole.name }}
subjects:
  - kind: ServiceAccount
    name: {{ include "homework-app.serviceAccountName" . }}
    namespace: {{ .Values.namespace }}
{{- end }}
EOF

# templates/storageclass.yaml
cat > templates/storageclass.yaml <<'EOF'
{{- if .Values.storageClass.enabled }}
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: {{ .Values.storageClass.name }}
  labels:
    {{- include "homework-app.labels" . | nindent 4 }}
provisioner: {{ .Values.storageClass.provisioner }}
reclaimPolicy: {{ .Values.storageClass.reclaimPolicy }}
volumeBindingMode: {{ .Values.storageClass.volumeBindingMode }}
{{- end }}
EOF

# templates/pvc.yaml
cat > templates/pvc.yaml <<'EOF'
{{- if .Values.persistence.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "homework-app.fullname" . }}-pvc
  namespace: {{ .Values.namespace }}
  labels:
    {{- include "homework-app.labels" . | nindent 4 }}
spec:
  accessModes:
    - {{ .Values.persistence.accessMode }}
  storageClassName: {{ .Values.persistence.storageClassName }}
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
{{- end }}
EOF

# templates/configmap.yaml
cat > templates/configmap.yaml <<'EOF'
{{- if .Values.configMap.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "homework-app.fullname" . }}-config
  namespace: {{ .Values.namespace }}
  labels:
    {{- include "homework-app.labels" . | nindent 4 }}
data:
{{- toYaml .Values.configMap.data | nindent 2 }}
{{- end }}
EOF

# templates/deployment.yaml
cat > templates/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "homework-app.fullname" . }}
  namespace: {{ .Values.namespace }}
  labels:
    {{- include "homework-app.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  strategy:
    type: {{ .Values.strategy.type }}
    {{- if eq .Values.strategy.type "RollingUpdate" }}
    rollingUpdate:
      maxUnavailable: {{ .Values.strategy.maxUnavailable }}
    {{- end }}
  selector:
    matchLabels:
      {{- include "homework-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "homework-app.selectorLabels" . | nindent 8 }}
    spec:
      serviceAccountName: {{ include "homework-app.serviceAccountName" . }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      volumes:
        - name: shared-volume
          persistentVolumeClaim:
            claimName: {{ include "homework-app.fullname" . }}-pvc
        {{- if .Values.configMap.enabled }}
        - name: config-volume
          configMap:
            name: {{ include "homework-app.fullname" . }}-config
        {{- end }}
      initContainers:
        {{- if .Values.initContainers.downloadIndex.enabled }}
        - name: init-download-index
          image: "{{ .Values.initContainers.downloadIndex.image.repository }}:{{ .Values.initContainers.downloadIndex.image.tag }}"
          command: {{- toYaml .Values.initContainers.downloadIndex.command | nindent 12 }}
          volumeMounts:
            - name: shared-volume
              mountPath: /init
        {{- end }}
        {{- if .Values.initContainers.fetchMetrics.enabled }}
        - name: fetch-metrics
          image: "{{ .Values.initContainers.fetchMetrics.image.repository }}:{{ .Values.initContainers.fetchMetrics.image.tag }}"
          command: {{- toYaml .Values.initContainers.fetchMetrics.command | nindent 12 }}
          volumeMounts:
            - name: shared-volume
              mountPath: /init
        {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          volumeMounts:
            - name: shared-volume
              mountPath: /usr/share/nginx/html
            {{- if .Values.configMap.enabled }}
            - name: config-volume
              mountPath: /usr/share/nginx/html/conf
            {{- end }}
          {{- if .Values.probes.readiness.enabled }}
          readinessProbe:
            httpGet:
              path: {{ .Values.probes.readiness.path }}
              port: {{ .Values.probes.readiness.port }}
            initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
          {{- end }}
          {{- if .Values.probes.liveness.enabled }}
          livenessProbe:
            httpGet:
              path: {{ .Values.probes.liveness.path }}
              port: {{ .Values.probes.liveness.port }}
          {{- end }}
          {{- if .Values.lifecycle.preStop.enabled }}
          lifecycle:
            preStop:
              exec:
                command: {{- toYaml .Values.lifecycle.preStop.command | nindent 18 }}
          {{- end }}
EOF

# templates/service.yaml
cat > templates/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ include "homework-app.fullname" . }}
  namespace: {{ .Values.namespace }}
  labels:
    {{- include "homework-app.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      protocol: TCP
      name: http
  selector:
    {{- include "homework-app.selectorLabels" . | nindent 4 }}
EOF

# templates/NOTES.txt
cat > templates/NOTES.txt <<'EOF'
Спасибо за установку {{ .Chart.Name }}!

Ваше приложение развёрнуто в namespace: {{ .Values.namespace }}

Для доступа к приложению выполните:

  kubectl port-forward --namespace {{ .Values.namespace }} svc/{{ include "homework-app.fullname" . }} 8080:{{ .Values.service.port }}
  
  После запуска port-forward откройте в браузере:
  - http://localhost:8080/index.html - главная страница
  - http://localhost:8080/metrics.html - метрики Kubernetes

{{- if .Values.redis.enabled }}

Redis развёрнут как зависимость:
  Сервис: {{ .Release.Name }}-redis-master
  Порт: 6379
  
  Подключение к Redis:
    kubectl run --namespace {{ .Values.namespace }} redis-client --rm --tty -i --restart='Never' --image redis:latest -- bash
    redis-cli -h {{ .Release.Name }}-redis-master
{{- end }}

Проверить статус deployment:
  kubectl --namespace {{ .Values.namespace }} get deployments {{ include "homework-app.fullname" . }}

Посмотреть поды:
  kubectl --namespace {{ .Values.namespace }} get pods -l "app.kubernetes.io/name={{ include "homework-app.name" . }},app.kubernetes.io/instance={{ .Release.Name }}"

Посмотреть логи:
  kubectl --namespace {{ .Values.namespace }} logs -l "app.kubernetes.io/name={{ include "homework-app.name" . }}" -f
EOF

echo "✓ Все templates созданы"
echo ""
echo "========================================="
echo "Helm Chart создан успешно!"
echo "========================================="
