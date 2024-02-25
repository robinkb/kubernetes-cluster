package templates

import (
	helmrelease "helm.toolkit.fluxcd.io/helmrelease/v2beta2"
)

#HelmRelease: helmrelease.#HelmRelease & {
	#config:  #Config
	kind:     "HelmRelease"
	metadata: #config.metadata
	spec: {
		chart: spec: {
			sourceRef: {
				kind: #HelmRepository.kind
				name: #HelmRepository.metadata.name
			}
			chart:   "coredns"
			version: "1.29.0"
		}
		driftDetection: {
			mode: "warn"
		}
		interval:    "1h"
		releaseName: "coredns"
		upgrade: {
			crds: "CreateReplace"
		}
		values: {
			image: {
				repository: "registry.k8s.io/coredns/coredns"
				tag:        "v1.10.1"
			}

			replicaCount: 2

			service: {
				clusterIP: #config.serviceIP
			}
		}
	}
}
