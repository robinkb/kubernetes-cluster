package templates

import (
	kustomization "kustomize.toolkit.fluxcd.io/kustomization/v1"
)

#KustomizationNetworkAntrea: kustomization.#Kustomization & {
	#config: #Config
	metadata: {
		name: "cluster-network-system-antrea"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels
	}
	spec: kustomization.#KustomizationSpec & {
		interval: "60m"
		prune:    true
		sourceRef: {
			kind: #OCIRepositoryNetworkAntrea.kind
			name: #OCIRepositoryNetworkAntrea.metadata.name
		}
	}
}
