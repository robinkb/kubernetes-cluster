package templates

import (
	ocirepository "source.toolkit.fluxcd.io/ocirepository/v1beta2"
)

#OCIRepositoryNetworkAntrea: ocirepository.#OCIRepository & {
	#config: #Config
	kind:    "OCIRepository"
	metadata: {
		name: "cluster-network-system-antrea"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels
	}
	spec: ocirepository.#OCIRepositorySpec & {
		interval: "10m"
		url:      "oci://\(#config.ociRegistry.baseUrl)/modules/cluster/network-system/antrea"
		ref: tag:        #config.ociRegistry.tag
		secretRef: name: #ImagePullSecret.metadata.name
	}
}
