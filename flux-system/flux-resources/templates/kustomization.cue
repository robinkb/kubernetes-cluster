package templates

import (
	kustomization "kustomize.toolkit.fluxcd.io/kustomization/v1"
)

#KustomizationNetworkAntrea: kustomization.#Kustomization & {
	#config: #Config
	metadata: {
		name:      "cluster-network-system-antrea"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: kustomization.#KustomizationSpec & {
		interval: "60m"
		prune:    true
		wait:     true
		sourceRef: {
			kind: #OCIRepositoryNetworkAntrea.kind
			name: #OCIRepositoryNetworkAntrea.metadata.name
		}
		healthChecks: [{
			apiVersion: "helm.toolkit.fluxcd.io/v2beta1"
			kind:       "HelmRelease"
			name:       "antrea"
			namespace:  "network-system"
		}]
	}
}

#KustomizationNetworkCoreDNS: kustomization.#Kustomization & {
	#config: #Config
	metadata: {
		name:      "cluster-network-system-coredns"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: kustomization.#KustomizationSpec & {
		interval: "60m"
		prune:    true
		wait:     true
		sourceRef: {
			kind: #OCIRepositoryNetworkCoreDNS.kind
			name: #OCIRepositoryNetworkCoreDNS.metadata.name
		}
		healthChecks: [{
			apiVersion: "helm.toolkit.fluxcd.io/v2beta1"
			kind:       "HelmRelease"
			name:       "coredns"
			namespace:  "network-system"
		}]
	}
}
