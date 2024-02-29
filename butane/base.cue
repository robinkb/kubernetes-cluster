package config

import "strings"

machine: [ for machine in kubernetesCluster.machines if machine.bootstrap == true {machine}][0]

butane: #Butane & {
	version: "1.1.0"
	variant: "flatcar"

	storage: {
		_files: {
			"/etc/hostname": {
				contents:
					inline: machine.name
			}
			"/etc/NetworkManager/system-connections/static.nmconnection": {
				mode: 0o600
				contents: inline: """
                [connection]
                id=\(machine.nic)
                type=ethernet
                interface-name=\(machine.nic)

                [ipv4]
                address1=\(machine.ip)/\(strings.Split(kubernetesCluster.nodeNetwork.subnetRange, "/")[1]),\(kubernetesCluster.nodeNetwork.gateway)
                dns=\(kubernetesCluster.nodeNetwork.dns)
                may-fail=false
                method=manual

                [ipv6]
                method=disabled
                """
			}
		}
	}
	passwd: _users: core: {
		ssh_authorized_keys: kubernetesCluster.sshAuthorizedKeys
	}
	systemd: _units: {
		// Disables getting counted by Fedora.
		"rpm-ostree-countme.timer": {
			enabled: false
			mask:    true
		}}
}
