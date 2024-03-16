package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#DaemonSet: appsv1.#DaemonSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "DaemonSet"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "data"
	}
	spec: appsv1.#DaemonSetSpec & {
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: #config.metadata.name
				containers: [
					{
						name:            "volume"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						args: [
							"volume",
							"-dir=/var/lib/registry/volume",
							"-max=0",
						]
						ports: [{
							name:          "http"
							protocol:      "TCP"
							containerPort: 8080
							hostPort:      8080
						}]
						volumeMounts: [{
							name:      "registry"
							mountPath: "/var/lib/registry/volume"
						}]
					},
					{
						name:            "filer"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						volumeMounts: [{
							name:      "registry"
							mountPath: "/var/lib/registry/filer"
						}]
					},
				]
				hostNetwork: true
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
				volumes: [{
					name: "registry"
					hostPath: {
						path: "/var/lib/registry"
						type: "Directory"
					}
				}]
			}
		}
	}
}
