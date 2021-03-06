{{- define "swift_endpoint_host" -}}
    {{- if .Values.proxy_host -}}
        {{.Values.proxy_host}}
    {{- else -}}
        objectstore.{{.Values.global.region}}.{{.Values.global.domain}}
    {{- end -}}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_daemonset_annotations" }}
scheduler.alpha.kubernetes.io/tolerations: '[{"key":"species","value":"swift-storage"}]'
{{- if .Values.enable_statsd }}
prometheus.io/scrape: "true"
prometheus.io/port: "9102"
{{- end }}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_daemonset_volumes" }}
- name: swift-bin
  configMap:
    name: swift-bin
- name: swift-etc
  configMap:
    name: swift-etc
- name: swift-account-ring
  configMap:
    name: swift-account-ring
- name: swift-container-ring
  configMap:
    name: swift-container-ring
- name: swift-object-ring
  configMap:
    name: swift-object-ring
- name: swift-drives
  hostPath:
    path: /srv/node
- name: swift-cache
  hostPath:
    path: /var/cache/swift
- name: swift-drive-state
  hostPath:
    path: /run/swift-storage/state
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_standard_container" -}}
{{- $image   := index . 0 -}}
{{- $service := index . 1 -}}
{{- $context := index . 2 }}
- name: {{ $service }}
  image: {{$context.Values.global.docker_repo}}/ubuntu-source-swift-{{ $image }}-m3:{{ printf "image_version_swift_%s" $image | index $context.Values }}
  command:
    - /usr/bin/dumb-init
  args:
    - /bin/bash
    - /swift-bin/swift-start
    - {{ $service }}
  # privileged access required for /swift-bin/unmount-helper (TODO: use shared/slave mount namespace instead)
  securityContext:
    privileged: true
  env:
    - name: DEBUG_CONTAINER
      value: "false"
  volumeMounts:
    - mountPath: /swift-bin
      name: swift-bin
    - mountPath: /swift-etc
      name: swift-etc
    - mountPath: /swift-rings/account
      name: swift-account-ring
    - mountPath: /swift-rings/container
      name: swift-container-ring
    - mountPath: /swift-rings/object
      name: swift-object-ring
    - mountPath: /srv/node
      name: swift-drives
    - mountPath: /var/cache/swift
      name: swift-cache
    - mountPath: /swift-drive-state
      name: swift-drive-state
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift_statsd_exporter_container" }}
- name: statsd
  image: prom/statsd-exporter:{{.Values.image_version_auxiliary_statsd_exporter}}
  args: [ -statsd.mapping-config=/swift-etc/statsd-exporter.conf ]
  ports:
    - name: statsd
      containerPort: 9125
      protocol: UDP
    - name: metrics
      containerPort: 9102
  volumeMounts:
    - mountPath: /swift-etc
      name: swift-etc
{{- end -}}
