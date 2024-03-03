package butane

import "flamingo.systems/config/schemas"

#Config: {
	kubernetesCluster: schemas.#KubernetesCluster
	machine:           schemas.#Machine
}

#Instance: {
	config: #Config

	BootstrapMachine: Base & KubernetesNode & KubernetesInit & {#config: config}
}
