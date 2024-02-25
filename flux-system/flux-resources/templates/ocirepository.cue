package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"

	ocirepository "source.toolkit.fluxcd.io/ocirepository/v1beta2"
)

#OCIRepositoryNetworkAntrea: ocirepository.#OCIRepository & {
	#config: #Config
	kind:    "OCIRepository"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "network-system-antrea"
	}
	spec: ocirepository.#OCIRepositorySpec & {
		interval: "10m"
		url:      "oci://\(#config.ociRegistry.baseUrl)/modules/cluster/network-system/antrea"
		ref: tag:        #config.ociRegistry.tag
		secretRef: name: #ImagePullSecret.metadata.name
	}
}
