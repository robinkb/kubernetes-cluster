// cluster: _

bundle: {
	apiVersion: "v1alpha1"
	name:       "security-system"

	instances: {
		"cert-manager": {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
			namespace: "security-system"
			values: {
				repository: url: "https://charts.jetstack.io"
				chart: {
					name:    "cert-manager"
					version: "1.14.3"
				}
				helmValues: {
					global: leaderElection: namespace: "security-system"

					crds: enabled: true
					// This should be deprecated and the above valid, but not yet?
					installCRDs: true

					prometheus: serviceMonitor: enabled: true
				}
			}
		}

		"cert-manager-resources": {
			module: url: "file://../modules/cluster/security-system/cert-manager-resources"
			namespace: "security-system"
		}

		"external-secrets": {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
			namespace: "security-system"
			values: {
				repository: url: "https://charts.external-secrets.io"
				chart: {
					name:    "external-secrets"
					version: "0.9.13"
				}
				helmValues: {
					extendedMetricLabels: true

					serviceMonitor: enabled: true

					webhook: {
						certManager: {
							enabled: true
							cert: issuerRef: {
								kind: "ClusterIssuer"
								name: "self-signed"
							}
						}
					}
				}
			}
		}
	}
}
