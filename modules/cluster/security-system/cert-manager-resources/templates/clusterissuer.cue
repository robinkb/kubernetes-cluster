package templates

import (
	certmanager "cert-manager.io/clusterissuer/v1"
)

#ClusterIssuer: certmanager.#ClusterIssuer & {
	#config: #Config
	metadata: {
		name:      "self-signed"
		labels:    #config.metadata.labels
	}
	spec: certmanager.#ClusterIssuerSpec & {
		selfSigned: {}
	}
}
