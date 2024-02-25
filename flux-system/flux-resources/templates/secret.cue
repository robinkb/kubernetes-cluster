package templates

import (
	"encoding/json"
	"encoding/base64"
	"strings"
	// timoniv1 "timoni.sh/core/v1alpha1"
	corev1 "k8s.io/api/core/v1"
)

#ImagePullSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "oci-registry-auth"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "kubernetes.io/dockerconfigjson"
	stringData: {
		".dockerconfigjson": json.Marshal({
			auths:
				"\(_ociRegistryHost)": {
					username: #config.ociRegistry.username
					password: #config.ociRegistry.password
					auth:     base64.Encode(null, "\(#config.ociRegistry.username):\(#config.ociRegistry.password)")
				}
		})
	}
	_ociRegistryHost: strings.Split(#config.ociRegistry.baseUrl, "/")[0]
}
