package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"

	corev1 "k8s.io/api/core/v1"
)

#HeadlessService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "headless"
	}
	spec: corev1.#ServiceSpec & {
		type:      corev1.#ServiceTypeClusterIP
		clusterIP: "None"
		selector:  #config.selector.labels
	}
}

#RPCService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "rpc"
	}
	spec: corev1.#ServiceSpec & {
		type:     corev1.#ServiceTypeClusterIP
		selector: #config.selector.labels
		ports: [{
			name:       "rpc"
			protocol:   "TCP"
			port:       8081
			targetPort: "rpc"
		}]
	}
}

#HTTPService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "http"
	}
	spec: corev1.#ServiceSpec & {
		type:     corev1.#ServiceTypeLoadBalancer
		selector: #config.selector.labels
		ports: [{
			name:       "http"
			protocol:   "TCP"
			port:       8080
			targetPort: "http"
		}]
	}
}
