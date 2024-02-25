package templates

import (
	helmrepository "source.toolkit.fluxcd.io/helmrepository/v1beta2"
)

#HelmRepository: helmrepository.#HelmRepository & {
	#config: #Config
	kind:    "HelmRepository"
	metadata: #config.metadata & {name: "antrea"}
	spec: helmrepository.#HelmRepositorySpec & {
		url: "https://charts.antrea.io"
	}
}
