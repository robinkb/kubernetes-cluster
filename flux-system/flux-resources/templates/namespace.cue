package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#NamespaceNetworkSystem: corev1.#Namespace & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Namespace"
	metadata: {
		name: "network-system"
	}
}
