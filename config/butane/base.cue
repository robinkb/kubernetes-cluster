package butane

import (
	"strings"
	
	"flamingo.systems/config/schemas"
)

Base: schemas.#Butane & {
	#config: #Config

	version: "1.5.0"
	variant: "fcos"

	storage: {
		#files: {
			"/etc/hostname": {
				contents:
					inline: #config.machine.name
			}
			"/etc/NetworkManager/system-connections/static.nmconnection": {
				mode: 0o600
				contents: inline: """
                [connection]
                id=\(#config.machine.nic)
                type=ethernet
                interface-name=\(#config.machine.nic)

                [ipv4]
                address1=\(#config.machine.ip)/\(strings.Split(#config.kubernetesCluster.nodeNetwork.subnetRange, "/")[1]),\(#config.kubernetesCluster.nodeNetwork.gateway)
                dns=\(#config.kubernetesCluster.nodeNetwork.dns)
                may-fail=false
                method=manual

                [ipv6]
                method=disabled
                """
			}
		}
	}
	passwd: #users: core: {
		ssh_authorized_keys: #config.kubernetesCluster.sshAuthorizedKeys
	}
	systemd: #units: {
		// Disables getting counted by Fedora.
		"rpm-ostree-countme.timer": {
			enabled: false
			mask:    true
		}}
}
