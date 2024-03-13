import "strings"

// This makes Timoni's bundle correctly pass through config loaded
// from another file through stdin.
cluster: _

bundle: {
	apiVersion: "v1alpha1"
	name:       "cluster"
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
				expose: {
					notificationServer: true
					sourceServer:       true
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

		"tofu-controller": {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
			namespace: "flux-system"
			values: {
				repository: url: "https://flux-iac.github.io/tofu-controller/"
				chart: {
					name:    "tf-controller"
					version: "0.15.1"
				}
				helmValues: {
					fullnameOverride: "tofu-controller"
					awsPackage: install: false
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

		// Deploy resources before kubelet-csr-approver so that the DNS
		// queries succeed when it first starts.
		"kubelet-csr-approver-resources": {
			module: url: "file://../modules/cluster/machine-system/kubelet-csr-approver-resources"
			namespace: "machine-system"
			values: {
				machines: cluster.machines
			}
		}

		"kubelet-csr-approver": {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
			namespace: "machine-system"
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

		longhorn: {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
			namespace: "storage-system"
			values: {
				repository: url: "https://charts.longhorn.io"
				chart: {
					name:    "longhorn"
					version: "1.5.1"
				}
				helmValues: {
					global: {
						cattle: {
							systemDefaultRegistry: "docker.io"
						}
					}

					// https://longhorn.io/docs/1.5.1/references/settings/
					defaultSettings: {
						// == WARNING WARNING WARNING WARNING WARNING ==
						// Set to true before uninstalling Longhorn. Leads to data loss.
						deletingConfirmationFlag: false
						// == WARNING WARNING WARNING WARNING WARNING ==

						// Defaults to 0, which means disabled. I should look into enabling this
						// if upgrades seem to go smoothly.
						concurrentAutomaticEngineUpgradePerNodeLimit: 0
						// This is very application-dependent, and so should be set through the StorageClass.
						defaultDataLocality: "disabled"
						// Ignition config is setup so that there is an empty partition mounted on this path.
						// Will need to change this if I ever want to support multiple disks.
						defaultDataPath: "/var/lib/longhorn"
						// Force-delete pods on down nodes so that the volume can be released and replacements scheduled.
						nodeDownPodDeletionPolicy: "delete-both-statefulset-and-deployment-pod"

						// Rebuilding replicas faster sounds good?
						fastReplicaRebuildEnabled: true
						// Check for data integrity even when no snapshots are created. Can detect bit rot.
						snapshotDataIntegrity: "enabled"
						// Check integrity at 2:00 on every 7th day of the month.
						snapshotDataIntegrityCronjob: "0 2 */7 * *"

						// Good to know that this exists in case it's ever a problem.
						orphanAutoDeletion: false

						// If a volume is detached, Longhorn will attach it to perform backups/snapshots.
						// If the workload comes back online while Longhorn is using the volume, the workload has to wait.
						allowRecurringJobWhileVolumeDetached: true

						// TODO: Enable overriding variables per environment and default this to false.
						// allowVolumeCreationWithDegradedAvailability: false

						// Try to balance replicas across different nodes for best availability.
						replicaAutoBalance: "best-effort"
						// Longhorn has a dedicated disk (partition...), so no need to reserve space.
						storageReservedPercentageForDefaultDisk: "0"

						// ~~ Danger Zone ~~
						// TODO: Define priority classes and set one here.
						// priorityClass: ""
					}

					persistence: {
						// Avoid using the included Longhorn storage.class by default.
						defaultClass: false
					}
				}
			}
		}

		"longhorn-resources": {
			module: url: "file://../modules/cluster/storage-system/longhorn-resources"
			namespace: "storage-system"
		}

		"matchbox": {
			module: url: "file://../modules/cluster/machine-system/matchbox"
			namespace: "machine-system"
		}
	}
}
