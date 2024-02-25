package config

values: {
	controllers: {
		helm: enabled:         true
		kustomize: enabled:    true
		notification: enabled: true
	}
	// Flux is installed before the CNI, so must be in host network.
	hostNetwork:     true
	securityProfile: "privileged"
	env: {
		"KUBERNETES_SERVICE_HOST": kubernetesCluster.controlPlaneEndpoint
		"KUBERNETES_SERVICE_PORT": "6443"
	}
}
