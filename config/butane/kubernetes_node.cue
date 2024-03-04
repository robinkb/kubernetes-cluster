package butane

import (
	"encoding/yaml"
	
	"flamingo.systems/config/schemas"
)

KubernetesNode: schemas.#Butane & {
	#config: #Config

	storage: {
		#disks: {
			"/dev/disk/by-id/coreos-boot-disk": {
				// We do not want to wipe the partition table because
				// this is the primary device.
				wipe_table: false
				#partitions: {
					"4": {
						label:    "root"
						size_mib: 8 * 1024
						resize:   true
					}
					"5": {
						size_mib: 50 * 1024
						// We assign a descriptive label to the partition.
						// This allows for referring to it in a device-agnostic
						// way in other parts of the configuration.
						label: "var"
					}
					"6": {
						// Take the remainder of the disk.
						size_mib: 0
						label:    "data-nvme"
					}
				}
			}
		}
		#filesystems: {
			"/var": {
				device:          "/dev/disk/by-partlabel/var"
				format:          "xfs"
				wipe_filesystem: true
				with_mount_unit: true
			}
			"/var/lib/longhorn": {
				device: "/dev/disk/by-partlabel/data-nvme"
				format: "ext4"
				// Longhorn's data should not be wiped.
				wipe_filesystem: false
				with_mount_unit: true
			}
		}
		#directories: {
			"/etc/kubernetes/manifests": {}
		}
		#files: {
			"/usr/local/bin/kubectl": {
				mode: 0o755
				contents: source: "https://dl.k8s.io/v\(#config.kubernetesCluster.kubernetesVersion)/bin/linux/amd64/kubectl"
			}
			"/usr/local/bin/kubeadm": {
				mode: 0o755
				contents: source: "https://dl.k8s.io/v\(#config.kubernetesCluster.kubernetesVersion)/bin/linux/amd64/kubeadm"
			}
			"/usr/local/bin/kubelet": {
				mode: 0o755
				contents: source: "https://dl.k8s.io/v\(#config.kubernetesCluster.kubernetesVersion)/bin/linux/amd64/kubelet"
			}
			"/etc/systemd/system/kubelet.service": {
				contents: source: "https://raw.githubusercontent.com/kubernetes/release/v\(#config.kubernetesCluster.kubepkgVersion)/cmd/kubepkg/templates/latest/rpm/kubelet/kubelet.service"
			}
			"/etc/systemd/system/kubelet.service.d/10-kubeadm.conf": {
				contents: source: "https://raw.githubusercontent.com/kubernetes/release/v\(#config.kubernetesCluster.kubepkgVersion)/cmd/kubepkg/templates/latest/rpm/kubeadm/10-kubeadm.conf"
			}
			"/etc/sysctl.d/10-kubernetes.conf": {
				contents: inline: """
					net.ipv4.ip_forward = 1
					net.bridge.bridge-nf-call-iptables = 1
					net.bridge.bridge-nf-call-ip6tables = 1
					"""
			}
			"/etc/modules-load.d/10-kubernetes.conf": {
				contents: inline: "br_netfilter"
			}
			"/etc/sysconfig/kubelet": {
				contents: inline: "KUBELET_EXTRA_ARGS=--node-ip=\(#config.machine.ip)"
			}
			// TODO: Port over at some point
			"/etc/kubeadm.yaml": {
				#append: {
					clusterConfiguration: {
						inline: "---\n" + yaml.Marshal({
							apiVersion: "kubeadm.k8s.io/v1beta3"
							kind:       "ClusterConfiguration"
							apiServer: {
								timeoutForControlPlane: "4m0s"
							}
							certificatesDir:      "/etc/kubernetes/pki"
							clusterName:          #config.kubernetesCluster.name
							controlPlaneEndpoint: #config.kubernetesCluster.controlPlaneEndpoint
							controllerManager: {
								extraArgs: {
									// Default location /usr/libexec is read-only in CoreOS.
									"flex-volume-plugin-dir": "/usr/local/libexec/kubernetes/kubelet-plugins/volume/exec/"
								}
							}
							dns: {}
							etcd: {
								local: {
									dataDir: "/var/lib/etcd"
								}
							}
							imageRepository:   "registry.k8s.io"
							kubernetesVersion: #config.kubernetesCluster.kubernetesVersion
							networking: {
								dnsDomain:     #config.kubernetesCluster.clusterNetwork.dnsDomain
								podSubnet:     #config.kubernetesCluster.clusterNetwork.podSubnet
								serviceSubnet: #config.kubernetesCluster.clusterNetwork.serviceSubnet
							}
							scheduler: {}
						})
					}
					kubeletConfiguration: {
						inline: "---\n" + yaml.Marshal({
							apiVersion: "kubelet.config.k8s.io/v1beta1"
							kind:       "KubeletConfiguration"
							authentication: {
								anonymous: {
									enabled: false
								}
								webhook: {
									cacheTTL: "0s"
									enabled:  true
								}
								x509: {
									clientCAFile: "/etc/kubernetes/pki/ca.crt"
								}
							}
							authorization: {
								mode: "Webhook"
								webhook: {
									cacheAuthorizedTTL:   "0s"
									cacheUnauthorizedTTL: "0s"
								}
							}
							// cgroupDriver is the driver kubelet uses to manipulate CGroups on the host
							// (cgroupfs or systemd). The host uses systemd already, so we should stick
							// with that to avoid having two separate views of cgroups.
							cgroupDriver:  "systemd"
							clusterDNS:    #config.kubernetesCluster.clusterNetwork.dnsIP
							clusterDomain: #config.kubernetesCluster.clusterNetwork.dnsDomain
							// containerRuntimeEndpoint is the endpoint of container runtime.
							// Currently only cri-o is supported.
							containerRuntimeEndpoint: "unix:///var/run/crio/crio.sock"
							// cpuManagerReconcilePeriod is the reconciliation period for the CPU Manager.
							cpuManagerReconcilePeriod: "10s"
							// evictionPressureTransitionPeriod is the duration for which the kubelet
							// has to wait before transitioning out of an eviction pressure condition.
							evictionPressureTransitionPeriod: "5ms"
							// fileCheckFrequency is the duration between checking config files for new data.
							fileCheckFrequency: "20s"
							healthzBindAddress: "127.0.0.1"
							healthzPort:        10248
							// httpCheckFrequency is the duration between checking http for new data.
							httpCheckFrequency: "20s"
							// imageMinimumGCAge is the minimum age for an unused image before it is
							// garbage collected.
							imageMinimumGCAge: "2m"
							// imageMaximumGCAge is the maximum age an image can be unused before it is
							// garbage collected.
							imageMaximumGCAge: "7d"
							// imageGCHighThresholdPercent is the percent of disk usage after which image
							// garbage collection is always run. The percent is calculated by dividing this
							// field value by 100, so this field must be between 0 and 100, inclusive.
							// When specified, the value must be greater than imageGCLowThresholdPercent.
							imageGCHighThresholdPercent: 85
							// imageGCLowThresholdPercent is the percent of disk usage before which image
							// garbage collection is never run. Lowest disk usage to garbage collect to.
							// The percent is calculated by dividing this field value by 100, so the
							// field value must be between 0 and 100, inclusive.
							// When specified, the value must be less than imageGCHighThresholdPercent.
							imageGCLowThresholdPercent: 50
							logging: {
								flushFrequency: 0
								options: {
									json: {
										infoBufferSize: 0
									}
								}
								verbosity: 0
							}
							maxParallelImagePulls: 5
							memorySwap: {}
							// nodeStatusReportFrequency is the frequency that kubelet posts node status
							// to master if node status does not change. Kubelet will ignore this frequency
							// and post node status immediately if any change is detected.
							// It is only used when node lease feature is enabled.
							nodeStatusReportFrequency: "5m"
							// nodeLeaseDurationSeconds is the duration the Kubelet will set on its
							// corresponding Lease. NodeLease provides an indicator of node health
							// by having the Kubelet create and periodically renew a lease,
							// named after the node, in the kube-node-lease namespace. If the lease
							// expires, the node can be considered unhealthy.
							nodeLeaseDurationSeconds:        10
							resolveConfig:                   "/run/systemd/resolve/resolv.conf"
							rotateCertificates:              true
							runtimeRequestTimeout:           "2m"
							serializeImagePulls:             false
							serverTLSBootstrap:              true
							shutdownGracePeriod:             "10m"
							shutdownGracePeriodCriticalPods: "0s"
							staticPodPath:                   "/etc/kubernetes/manifests"
							streamingConnectionIdleTimeout:  "4h"
							syncFrequency:                   "1m"
							volumeStatsAggPeriod:            "1m"
						})
					}
				}
			}
			if #config.machine.role == "controller" {
				"/etc/kubernetes/manifests/kube-vip.yaml": {
					contents: inline: yaml.Marshal({
						apiVersion: "v1"
						kind:       "Pod"
						metadata: {
							name:      "kube-vip"
							namespace: "kube-system"
						}
						spec: {
							containers: [{
								name:  "kube-vip"
								image: "ghcr.io/kube-vip/kube-vip:v0.6.2"
								args: ["manager"]
								env: [{
									name:  "vip_arp"
									value: "true"
								}, {
									name:  "port"
									value: "6443"
								}, {
									name:  "vip_interface"
									value: #config.machine.nic
								}, {
									name:  "vip_cidr"
									value: "32"
								}, {
									name:  "cp_enable"
									value: "true"
								}, {
									name:  "cp_namespace"
									value: "kube-system"
								}, {
									name:  "vip_ddns"
									value: "false"
								}, {
									name:  "vip_leaderelection"
									value: "true"
								}, {
									name:  "vip_leasename"
									value: "plndr-cp-lock"
								}, {
									name:  "vip_leaseduration"
									value: "5"
								}, {
									name:  "vip_renewdeadline"
									value: "3"
								}, {
									name:  "vip_retryperiod"
									value: "1"
								}, {
									name:  "address"
									value: #config.kubernetesCluster.controlPlaneEndpoint
								}, {
									name:  "prometheus_server"
									value: ":2112"
								}]
								resources: {}
								securityContext: capabilities: add: [
									"NET_ADMIN",
									"NET_RAW",
								]
								volumeMounts: [{
									mountPath: "/etc/kubernetes/admin.conf"
									name:      "kubeconfig"
								}]
							}]
							hostAliases: [{
								hostnames: ["kubernetes"]
								ip: "127.0.0.1"
							}]
							hostNetwork: true
							volumes: [{
								hostPath: path: "/etc/kubernetes/admin.conf"
								name: "kubeconfig"
							}]
						}
					})
				}
			}
		}
	}
	systemd: #units: {
		"rpm-ostree-extra-packages.service": {
			enabled: true
			contents: """
				[Unit]
				Description=Layer cri-o with rpm-ostree
				Wants=network-online.target
				After=network-online.target
				# We run before `zincati.service` to avoid conflicting rpm-ostree transactions.
				Before=zincati.service
				ConditionPathExists=!/usr/bin/crictl

				[Service]
				Type=oneshot
				# CRI-O version should be matched to the Kubernetes version,
				# but that's a pain and this is probably fine.
				ExecStart=/usr/bin/rpm-ostree install --apply-live cri-o cri-tools conntrack-tools
				ExecStart=/usr/bin/systemctl enable --now crio.service

				[Install]
				WantedBy=multi-user.target
				"""
		}
		"crio-remove-default-cni.service": {
			enabled: true
			contents: """
				[Unit]
				Description=Remove default cri-o CNI configurations
				ConditionPathExists=|/etc/cni/net.d/100-crio-bridge.conflist
				ConditionPathExists=|/etc/cni/net.d/200-loopback.conflist

				[Service]
				# We bring our own CNI, so remove the defaults included with cri-o.
				ExecStart=/usr/bin/rm -vf /etc/cni/net.d/100-crio-bridge.conflist /etc/cni/net.d/200-loopback.conflist

				[Install]
				# Run before crio to ensure that it never boots up with the default CNI.
				WantedBy=crio.service
				WantedBy=multi-user.target
				"""
		}
		"containerd.service": {
			enabled: true
		}
		"kubelet.service": {
			enabled: true
			dropins: [{
				name: "20-kubelet.conf"
				contents: """
					[Service]
					ExecStart=
					ExecStart=/usr/local/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
					"""
			}]
		}
	}
}
