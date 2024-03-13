package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Endpoints: corev1.#Endpoints & {
	#config:    #Config
	#machine:   _
	apiVersion: "v1"
	kind:       "Endpoints"
	metadata: {
		name:      #machine.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	subsets: [{
		addresses: [{
			ip: #machine.ip
		}]
	}]
}
