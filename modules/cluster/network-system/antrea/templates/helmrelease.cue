package templates

import (
	helmrelease "helm.toolkit.fluxcd.io/helmrelease/v2beta2"
)

#HelmRelease: helmrelease.#HelmRelease & {
	#config: #Config
	kind:    "HelmRelease"
	metadata: #config.metadata
	spec: {
		chart: spec: {
            sourceRef: {
                kind: #HelmRepository.kind
                name: #HelmRepository.metadata.name
            }
			chart:   "antrea"
			version: "1.13.1"
		}
		driftDetection: {
			mode: "warn"
		}
		interval:    "1h"
		releaseName: "antrea"
		upgrade: {
			crds: "CreateReplace"
		}
		values: {
			kubeAPIServerOverride: "https://\(#config.controlPlaneEndpoint):6443"
			trafficEncapMode:      "hybrid"

			antreaProxy: proxyAll: true
		}
	}
}
