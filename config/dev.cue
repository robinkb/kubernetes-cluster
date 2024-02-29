package config

ociRegistry: #OCIRegistry & {
	baseUrl: "ghcr.io/robinkb/kubernetes-cluster"
	tag:     "testing"
}

kubernetesCluster: #KubernetesCluster & {
	name: "flamingo-testing"

	kubernetesVersion: "1.27.11"
	kubepkgVersion:    "0.15.1"

	controlPlaneEndpoint: "192.168.124.5"

	dnsZone: {
		name: "flamingo.test"
		ipAddresses: [
			"192.168.124.20",
			"192.168.124.21",
		]
	}

	nodeNetwork: {
		subnetRange:       "192.168.124.0/24"
		loadBalancerRange: "192.168.124.32/28"
		dns:               gateway
		gateway:           "192.168.124.1"
	}

	sshAuthorizedKeys: [
		"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK3LVCNXXftJseibqomy46wkkdmXml9svt+WNRSZQOx9 robinkb@slate",
		"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIbjoDEQEE3xSoQvFca1+lOSTEhtFoZMsVo5UCZt162c robinkb@conswole",
	]

	_virtualMachine: {
		nic:        "enp1s0"
		installDev: "/dev/vda"
	}

	machines: {
		primero: _virtualMachine & {
			role:      "controller"
			bootstrap: true
			mac:       "52:54:00:29:28:01"
			ip:        "192.168.124.11"
		}
		segundo: _virtualMachine & {
			role: "controller"
			mac:  "52:54:00:29:28:02"
			ip:   "192.168.124.12"
		}
		tercero: _virtualMachine & {
			role: "controller"
			mac:  "52:54:00:29:28:03"
			ip:   "192.168.124.13"
		}
		cuatro: _virtualMachine & {
			mac: "52:54:00:29:28:04"
			ip:  "192.168.124.14"
		}
		quinto: _virtualMachine & {
			mac: "52:54:00:29:28:05"
			ip:  "192.168.124.15"
		}
		sexto: _virtualMachine & {
			mac: "52:54:00:29:28:06"
			ip:  "192.168.124.16"
		}
	}
}
