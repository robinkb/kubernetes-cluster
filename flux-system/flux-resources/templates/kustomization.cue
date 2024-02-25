package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"

	kustomization "kustomize.toolkit.fluxcd.io/kustomization/v1"
)

#KustomizationNetworkAntrea: kustomization.#Kustomization & {
	#config: #Config
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "network-system-antrea"
	}
	spec: kustomization.#KustomizationSpec & {
		interval: "60m"
		prune:    true
		sourceRef: {
			kind: #OCIRepositoryNetworkAntrea.kind
			// The following line makes more sense, but throws an error.
			// name: #OCIRepositoryNetwork.metadata.name
			name: metadata.name
		}
	}
}
