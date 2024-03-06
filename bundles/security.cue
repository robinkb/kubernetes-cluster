import "strings"

cluster: _

bundle: {
	apiVersion: "v1alpha1"
	name:       "security-system"

	instances: {
		"kubelet-csr-approver": {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
			namespace: "security-system"
			values: {
				repository: url: "https://postfinance.github.io/kubelet-csr-approver"
				chart: {
					name:    "kubelet-csr-approver"
					version: "1.0.7"
				}
				helmValues: {
					replicas: 1

					providerRegex: "^\(strings.Join([ for machine in cluster.machines {machine.name}], "|"))$"
					providerIpPrefixes: [ for machine in cluster.machines {"\(machine.ip)/32"}]

					maxExpirationSeconds: ""
					// Enabled by a headless service per node that are created below.
					bypassDnsResolution: false
					allowedDnsNames:     1
					// optional, permits ignoring CSRs with another Username than `system:node:...`
					ignoreNonSystemNode: true
					// set this parameter to true to ignore mismatching DNS name and hostname
					bypassHostnameCheck: false
					// optional, list of IP (IPv4, IPv6) subnets that are allowed to submit CSRs
				}
			}
		}

		"kubelet-csr-approver-resources": {
			module: url: "file://../modules/cluster/security-system/kubelet-csr-approver-resources"
			namespace: "security-system"
			values: {
				machines: cluster.machines
			}
		}

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
