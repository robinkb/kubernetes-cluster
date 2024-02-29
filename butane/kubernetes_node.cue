import "encoding/yaml"

butane: #Butane & {
	storage: {
		_disks: {
			"/dev/disk/by-id/coreos-boot-disk": {
				// We do not want to wipe the partition table because
				// this is the primary device.
				wipe_table: false
				_partitions: {
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
		_filesystems: {
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
		_directories: {
			"/etc/kubernetes/manifests": {}
		}
		_files: {
			"/usr/local/bin/kubectl": {
				mode: 0o755
				contents: source: "https://dl.k8s.io/v\(kubernetesCluster.kubernetesVersion)/bin/linux/amd64/kubectl"
			}
			"/usr/local/bin/kubeadm": {
				mode: 0o755
				contents: source: "https://dl.k8s.io/v\(kubernetesCluster.kubernetesVersion)/bin/linux/amd64/kubeadm"
			}
			"/usr/local/bin/kubelet": {
				mode: 0o755
				contents: source: "https://dl.k8s.io/v\(kubernetesCluster.kubernetesVersion)/bin/linux/amd64/kubelet"
			}
			"/etc/systemd/system/kubelet.service": {
				contents: source: "https://raw.githubusercontent.com/kubernetes/release/v\(kubernetesCluster.kubepkgVersion)/cmd/kubepkg/templates/latest/rpm/kubelet/kubelet.service"
			}
			"/etc/systemd/system/kubelet.service.d/10-kubeadm.conf": {
				contents: source: "https://raw.githubusercontent.com/kubernetes/release/v\(kubernetesCluster.kubepkgVersion)/cmd/kubepkg/templates/latest/rpm/kubeadm/10-kubeadm.conf"
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
				contents: inline: "KUBELET_EXTRA_ARGS=--node-ip=\(machine.ip)"
			}
			// TODO: Port over at some point
			// "/etc/kubeadm.yaml": {
			//  _append: node: inline:
			// }
			if machine.role == "controller" {
				"/etc/kubernetes/manifests/kube-vip.yaml": {
					contents: inline: yaml.Marshal({apiVersion: "v1"
								kind:                     "Pod"
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
									value: machine.nic
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
									value: kubernetesCluster.controlPlaneEndpoint
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
	systemd: _units: {
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
				RemainAfterExit=yes
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
