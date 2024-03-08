package templates

// Something wrong with the generated spec.
// import (
// 	externalsecret "external-secrets.io/externalsecret/v1beta1"
// )

#ExternalSecret: {
	#config:    #Config
	apiVersion: "external-secrets.io/v1beta1"
	kind:       "ExternalSecret"
	metadata: {
		name:      "longhorn-crypto-key"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		// Don't want to change the key.
		refreshInterval: "0"
		target: {
			name:      "longhorn-crypto-key"
            // Ensure that nothing short of deleting it will change the Secret.
			immutable: true
			template: {
				data: {
					CRYPTO_KEY_VALUE:    "{{ .password }}"
					CRYPTO_KEY_PROVIDER: "secret"
					CRYPTO_KEY_CIPHER:   "aes-xts-plain64"
					CRYPTO_KEY_HASH:     "sha256"
					CRYPTO_KEY_SIZE:     "256"
					CRYPTO_PBKDF:        "argon2i"
				}
			}
		}
		dataFrom: [{
			sourceRef: {
				generatorRef: {
					apiVersion: "generators.external-secrets.io/v1alpha1"
					kind:       "Password"
					name:       "longhorn-crypto-key"
				}
			}
		}]
	}
}
