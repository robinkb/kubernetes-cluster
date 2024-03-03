package schemas

import "net"

#Machine: {
	// Is this machine used to bootstrap the cluster?
	bootstrap:  bool | *false
	name:       string
	role:       *"worker" | "controller"
	nic:        string
	installDev: string
	mac:        =~"^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$"
	ip:         net.IPv4
}
