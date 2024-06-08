{{/*
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper Redis&reg; image name
*/}}
{{- define "redis-cluster.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the metrics image)
*/}}
{{- define "redis-cluster.metrics.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.metrics.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "redis-cluster.volumePermissions.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.volumePermissions.image "global" .Values.global) }}
{{- end -}}

{{/*
Return sysctl image
*/}}
{{- define "redis-cluster.sysctl.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.sysctlImage "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "redis-cluster.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.metrics.image) "global" .Values.global) -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "networkPolicy.apiVersion" -}}
{{- if semverCompare ">=1.4-0, <1.7-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiGroup for PodSecurityPolicy.
*/}}
{{- define "podSecurityPolicy.apiGroup" -}}
{{- if semverCompare ">=1.14-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "policy" -}}
{{- else -}}
{{- print "extensions" -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a TLS secret object should be created
*/}}
{{- define "redis-cluster.createTlsSecret" -}}
{{- if and .Values.tls.enabled .Values.tls.autoGenerated (not .Values.tls.existingSecret) (not .Values.tls.certificatesSecret) }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret containing Redis TLS certificates
*/}}
{{- define "redis-cluster.tlsSecretName" -}}
{{- $secretName := coalesce .Values.tls.existingSecret .Values.tls.certificatesSecret -}}
{{- if $secretName -}}
    {{- printf "%s" (tpl $secretName $) -}}
{{- else -}}
    {{- printf "%s-crt" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the path to the cert file.
*/}}
{{- define "redis-cluster.tlsCert" -}}
{{- if (include "redis-cluster.createTlsSecret" . ) -}}
    {{- printf "/opt/bitnami/redis/certs/%s" "tls.crt" -}}
{{- else -}}
    {{- required "Certificate filename is required when TLS in enabled" .Values.tls.certFilename | printf "/opt/bitnami/redis/certs/%s" -}}
{{- end -}}
{{- end -}}

{{/*
Return the path to the cert key file.
*/}}
{{- define "redis-cluster.tlsCertKey" -}}
{{- if (include "redis-cluster.createTlsSecret" . ) -}}
    {{- printf "/opt/bitnami/redis/certs/%s" "tls.key" -}}
{{- else -}}
    {{- required "Certificate Key filename is required when TLS in enabled" .Values.tls.certKeyFilename | printf "/opt/bitnami/redis/certs/%s" -}}
{{- end -}}
{{- end -}}

{{/*
Return the path to the CA cert file.
*/}}
{{- define "redis-cluster.tlsCACert" -}}
{{- if (include "redis-cluster.createTlsSecret" . ) -}}
    {{- printf "/opt/bitnami/redis/certs/%s" "ca.crt" -}}
{{- else -}}
    {{- required "Certificate CA filename is required when TLS in enabled" .Values.tls.certCAFilename | printf "/opt/bitnami/redis/certs/%s" -}}
{{- end -}}
{{- end -}}

{{/*
Return the path to the DH params file.
*/}}
{{- define "redis-cluster.tlsDHParams" -}}
{{- if .Values.tls.dhParamsFilename -}}
{{- printf "/opt/bitnami/redis/certs/%s" .Values.tls.dhParamsFilename -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "redis-cluster.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Get the password secret.
*/}}
{{- define "redis-cluster.secretName" -}}
{{- if .Values.existingSecret -}}
{{- printf "%s" (tpl .Values.existingSecret $) -}}
{{- else -}}
{{- printf "%s" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the password key to be retrieved from Redis&reg; secret.
*/}}
{{- define "redis-cluster.secretPasswordKey" -}}
{{- if and .Values.existingSecret .Values.existingSecretPasswordKey -}}
{{- printf "%s" .Values.existingSecretPasswordKey -}}
{{- else -}}
{{- printf "redis-password" -}}
{{- end -}}
{{- end -}}

{{/*
Return Redis&reg; password
*/}}
{{- define "redis-cluster.password" -}}
{{- if not (empty .Values.global.redis.password) }}
    {{- .Values.global.redis.password -}}
{{- else if not (empty .Values.password) -}}
    {{- .Values.password -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}

{{/*
Determines whether or not to create the Statefulset
*/}}
{{- define "redis-cluster.createStatefulSet" -}}
    {{- if not .Values.cluster.externalAccess.enabled -}}
        {{- true -}}
    {{- end -}}
    {{- if and .Values.cluster.externalAccess.enabled .Values.cluster.externalAccess.service.loadBalancerIP -}}
        {{- true -}}
    {{- end -}}
{{- end -}}

{{/* Check if there are rolling tags in the images */}}
{{- define "redis-cluster.checkRollingTags" -}}
{{- include "common.warnings.rollingTag" .Values.image -}}
{{- include "common.warnings.rollingTag" .Values.metrics.image -}}
{{- end -}}

{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "redis-cluster.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "redis-cluster.validateValues.updateParameters" .) -}}
{{- $messages := append $messages (include "redis-cluster.validateValues.tlsParameters" .) -}}
{{- $messages := append $messages (include "redis-cluster.validateValues.tls" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/* Validate values of Redis&reg; Cluster - check update parameters */}}
{{- define "redis-cluster.validateValues.updateParameters" -}}
{{- if and .Values.cluster.update.addNodes ( or (and .Values.cluster.externalAccess.enabled .Values.cluster.externalAccess.service.loadBalancerIP) ( not .Values.cluster.externalAccess.enabled )) -}}
  {{- if .Values.cluster.externalAccess.enabled }}
    {{- if not .Values.cluster.update.newExternalIPs -}}
redis-cluster: newExternalIPs
     You must provide the newExternalIPs to perform the cluster upgrade when using external access.
    {{- end -}}
  {{- else }}
    {{- if not .Values.cluster.update.currentNumberOfNodes -}}
redis-cluster: currentNumberOfNodes
    You must provide the currentNumberOfNodes to perform an upgrade when not using external access.
    {{- end -}}
    {{- if kindIs "invalid" .Values.cluster.update.currentNumberOfReplicas -}}
redis-cluster: currentNumberOfReplicas
    You must provide the currentNumberOfReplicas to perform an upgrade when not using external access.
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/* Validate values of Redis&reg; Cluster - tls settings */}}
{{- define "redis-cluster.validateValues.tlsParameters" -}}
{{- if and .Values.tls.enabled (not .Values.tls.autoGenerated) }}
{{- if and (not .Values.tls.existingSecret) (not .Values.tls.certificatesSecret) -}}
redis-cluster: TLSSecretMissingSecret
     A secret containing the certificates for the TLS traffic is required when TLS is enabled. Please set the tls.existingSecret value
{{- end -}}
{{- if not .Values.tls.certFilename -}}
redis-cluster: TLSSecretMissingCert
     A certificate filename is required when TLS is enabled. Please set the tls.certFilename value
{{- end -}}
{{- if not .Values.tls.certKeyFilename -}}
redis-cluster: TLSSecretMissingCertKey
     A certificate key filename is required when TLS is enabled. Please set the tls.certKeyFilename value
{{- end -}}
{{- if not .Values.tls.certCAFilename -}}
redis-cluster: TLSSecretMissingCertCA
     A certificate CA filename is required when TLS is enabled. Please set the tls.certCAFilename value
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Validate values of Redis&reg; - PodSecurityPolicy create */}}
{{- define "redis-cluster.validateValues.tls" -}}
{{- if and .Values.tls.enabled (not .Values.tls.autoGenerated) (not .Values.tls.existingSecret) (not .Values.tls.certificatesSecret) }}
redis-cluster: tls.enabled
    In order to enable TLS, you also need to provide
    an existing secret containing the TLS certificates or
    enable auto-generated certificates.
{{- end -}}
{{- end -}}

{{/* Fetches data content from a configmap */}}
{{- define "redis-cluster.getConfigMapData" -}}
{{- $name := .name }}
{{- $ns := default .Release.Namespace .namespace }}
{{- $data := dict }}
{{- with (lookup "v1" "ConfigMap" $ns $name) }}
{{- range $key, $value := .data }}
{{- $data = $data | merge (dict $key $value) }}
{{- end }}
{{- end }}
{{- $data }}
{{- end }}

{{/* Fetches data content form a secret */}}
{{- define "redis-cluster.getSecretData" -}}
{{- $name := .name }}
{{- $ns := default .Release.Namespace .namespace }}
{{- $data := dict }}
{{- with (lookup "v1" "Secret" $ns $name) }}
{{- range $key, $value := .data }}
{{- $decodedValue := $value | b64dec }}
{{- $data = $data | merge (dict $key $decodedValue) }}
{{- end }}
{{- end }}
{{- $data }}
{{- end }}

{{/* Merges data from all defined configmaps and/or secrets and removes duplicated data */}}
{{- define "mergeConfigMapsAndSecrets" -}}
{{- $merged := dict }}
{{- if .Values.redis.defaultConfigOverrideCM }}
  {{- range .Values.redis.defaultConfigOverrideCM }}
  {{- $merged = $merged | merge (include "getConfigMapData" (dict "name" .name)) }}
  {{- end }}
{{- end }}
{{- if .Values.redis.defaultConfigOverrideSecret }}
  {{- range .Values.redis.defaultConfigOverrideSecret }}
  {{- $merged = $merged | merge (include "getSecretData" (dict "name" .name)) }}
  {{- end }}
{{- end }}

{{- $unique := dict }}
{{- range $key, $value := $merged }}
{{- if not (hasKey $unique $key) }}
{{- $unique = $unique | merge (dict $key $value) }}
{{- end }}
{{- end }}
{{- $unique }}
{{- end }}
