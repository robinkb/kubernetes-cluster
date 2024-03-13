package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#StatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	#cmName:    string
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata:   #config.metadata
	spec: appsv1.#StatefulSetSpec & {
		replicas: 1
		selector: matchLabels: #config.selector.labels
		serviceName: "matchbox-headless"
		template: {
			metadata: {
				labels: #config.selector.labels
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: #config.metadata.name
				containers: [
					{
						name:            #config.metadata.name
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						args: [
							"-address=0.0.0.0:8080",
							"-rpc-address=0.0.0.0:8081",
							"-ca-file=/etc/matchbox/ca.crt",
							"-cert-file=/etc/matchbox/tls.crt",
							"-key-file=/etc/matchbox/tls.key",
						]
						ports: [
							{
								name:          "http"
								containerPort: 8080
								protocol:      "TCP"
							},
							{
								name:          "rpg"
								containerPort: 8081
								protocol:      "TCP"
							},
						]
						livenessProbe: {
							httpGet: {
								path: "/"
								port: "http"
							}
						}
						readinessProbe: {
							httpGet: {
								path: "/"
								port: "http"
							}
						}
						volumeMounts: [
							{
								name:      "certs"
								mountPath: "/etc/matchbox"
							},
							{
								name:      "data"
								mountPath: "/var/lib/matchbox"
							},
							{
								name:      "assets"
								mountPath: "/var/lib/matchbox/assets"
							},
						]
						resources:       #config.resources
						securityContext: #config.securityContext
					},
				]
				volumes: [
					{
						name: "certs"
						secret: {
							secretName: "matchbox-server"
						}
					},
				]
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
		volumeClaimTemplates: [{
			metadata: {
				name:   "data"
				labels: #config.metadata.labels
			}
			spec: {
				storageClassName: "lh-block-nvme-r2"
				accessModes: ["ReadWriteOnce"]
				resources: {
					requests: {
						storage: "1Gi"
					}
				}
			}
		}, {
			metadata: {
				name:   "assets"
				labels: #config.metadata.labels
			}
			spec: {
				storageClassName: "lh-block-nvme-r2"
				accessModes: ["ReadWriteOnce"]
				resources: {
					requests: {
						storage: "5Gi"
					}
				}
			}
		}]
	}
}
