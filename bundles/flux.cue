// This makes Timoni's bundle correctly pass through config loaded
// from another file through stdin.
cluster: _

bundle: {
	apiVersion: "v1alpha1"
	name:       "flux-aio"
	instances: {
		flux: {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-aio"
			namespace: "flux-system"
			values: {
				controllers: {
					helm: enabled:         true
					kustomize: enabled:    true
					notification: enabled: true
				}
				hostNetwork:     true
				securityProfile: "privileged"
				env: {
					"KUBERNETES_SERVICE_HOST": cluster.controlPlaneEndpoint
					"KUBERNETES_SERVICE_PORT": "6443"
				}
			}
		}

		// Install them early so that other charts/modules can install ServiceMonitors
		// before Prometheus (or whatever I end up using) is available.
		"prometheus-operator-crds": {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
			namespace: "monitoring"
			values: {
				repository: url: "https://prometheus-community.github.io/helm-charts"
				chart: {
					name:    "prometheus-operator-crds"
					version: "9.0.1"
				}
				helmValues: {}
			}
		}
	}
}
