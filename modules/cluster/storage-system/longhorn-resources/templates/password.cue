package templates

import (
	generators "generators.external-secrets.io/password/v1alpha1"
)

#Password: generators.#Password & {
	#config: #Config
	metadata: {
		name:      "longhorn-crypto-key"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: generators.#PasswordSpec & {
		length:      64
		allowRepeat: true
	}
}
