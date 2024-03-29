package butane

import (
	"encoding/yaml"
	
	"flamingo.systems/config/schemas"
)

KubernetesInit: schemas.#Butane & {
	#config: #Config

	storage: #files: {
		"/etc/kubeadm.yaml": {
			#append: {
				initConfiguration: {
					inline: "---\n" + yaml.Marshal({
						apiVersion: "kubeadm.k8s.io/v1beta3"
						kind:       "InitConfiguration"
						nodeRegistration: {
							criSocket: "unix:///var/run/crio/crio.sock"
							kubeletExtraArgs: {
								// Default location /usr/libexec is read-only in CoreOS.
								"volume-plugin-dir": "/usr/local/libexec/kubernetes/kubelet-plugins/volume/exec/"
							}
							// Having separate control plane is not yet supported.
							taints: []
						}
						localAPIEndpoint: {
							advertiseAddress: #config.machine.ip
							bindPort:         6443
						}
						skipPhases: [
							// ClusterConfiguration and KubeletConfiguration are managed by us.
							// Kubeadm always reads these from the cluster while joining a node.
							// The on-disk files are ignored. So must be modified in-cluster.
							"upload-config/kubeadm",
							"upload-config/kubelet",
							// We don't use the bootstrap token for joining nodes.
							"bootstrap-token",
							// We are installing CoreDNS ourselves for more control
							// over its management and to decouple CoreDNS from cluster provisioning.
							"addon/coredns",
							// We completely replace kube-proxy by whatever CNI we use.
							"addon/kube-proxy",
							// We don't join nodes manually in this house.
							"show-join-command",
						]
					})
				}
			}
		}
	}
	systemd: #units: {
		"kubeadm.service": {
			enabled: true
			contents: """
				[Unit]
				Description=Kubeadm service
				Before=zincati.service
				After=rpm-ostree-extra-packages.service
				Wants=crio.service
				ConditionPathExists=!/etc/kubernetes/kubelet.conf

				[Service]
				ExecStartPre=/usr/local/bin/kubeadm config images pull --config /etc/kubeadm.yaml
				ExecStart=/usr/local/bin/kubeadm init --config /etc/kubeadm.yaml
				Restart=on-failure
				RestartSec=5

				[Install]
				WantedBy=multi-user.target
				"""
		}
		"kubeconfig.service": {
			enabled: true
			contents: """
				[Unit]
				Description=Copy kubeconfig to home directory
				Requires=kubeadm.service
				After=kubeadm.service
				ConditionPathExists=!/home/core/.kube/config

				[Service]
				ExecStartPre=/usr/bin/mkdir -p /home/core/.kube
				ExecStartPre=/usr/bin/cp /etc/kubernetes/admin.conf /home/core/.kube/config
				ExecStart=/usr/bin/chown -R core:core /home/core/.kube
				Restart=on-failure
				RestartSec=5

				[Install]
				WantedBy=multi-user.target
				"""
		}
	}
}
