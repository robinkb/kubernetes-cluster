cluster: _

bundle: {
	apiVersion: "v1alpha1"
	name:       "network-system"

	instances: {
		antrea: {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
			namespace: "network-system"
			values: {
				repository: url: "https://charts.antrea.io"
				chart: {
					name:    "antrea"
					version: "1.13.1"
				}
				helmValues: {
					kubeAPIServerOverride: "https://\(cluster.controlPlaneEndpoint):6443"

					trafficEncapMode: "hybrid"

					antreaProxy: {
						proxyAll: true
					}
				}
			}
		}

		coredns: {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
			namespace: "network-system"
			values: {
				repository: url: "https://coredns.github.io/helm"
				chart: {
					name:    "coredns"
					version: "1.26.0"
				}
				helmValues: {
					// CoreDNS chart is not very smart with naming.
					fullnameOverride: "coredns"

					image: {
						repository: "registry.k8s.io/coredns/coredns"
						tag:        "v1.10.1"
					}

					replicaCount: 2

					service: {
						clusterIP: cluster.clusterNetwork.dnsIP[0]
					}

					serviceAccount: {
						create: true
					}
				}
			}
		}

		metallb: {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
			namespace: "network-system"
			values: {
				repository: url: "https://metallb.github.io/metallb"
				chart: {
					name:    "metallb"
					version: "0.13.11"
				}
				helmValues: {
					prometheus: {
						rbacPrometheus: false
						serviceMonitor: {
							enabled: true
						}
						prometheusRule: {
							enabled: true
						}
					}

					speaker: {
						frr: {
							// Defaults to running in BGP mode, I guess.
							enabled: false
						}
					}

					crds: {
						enabled: true
					}
				}
			}
		}

		"metallb-resources": {
			module: url: "file://../modules/cluster/network-system/metallb-resources"
			namespace: "network-system"
			values: {
				loadBalancerRange: cluster.nodeNetwork.loadBalancerRange
			}
		}
	}
}
