package schemas

import (
	"list"
	"net"
)

#KubernetesCluster: {
	name: string

	kubernetesVersion: string
	kubepkgVersion:    string

	controlPlaneEndpoint: net.IPv4

	dnsZone: {
		name:        string
		ipAddresses: list.Repeat([net.IPv4], 2)
	}

	nodeNetwork: {
		subnetRange: net.IPCIDR
		// Range within subnetRange reserved for load balancer IPs.
		loadBalancerRange: net.IPCIDR
		dns:               net.IPv4
		gateway:           net.IPv4
	}

	// Sensible defaults that use IPs from the CGNAT space.
	clusterNetwork: {
		podSubnet:     net.IPCIDR | *"100.64.0.0/10"
		serviceSubnet: net.IPCIDR | *"198.19.0.0/16"
		dnsIP:         [net.IPv4, ...] | *["198.19.0.10"]
		dnsIP:         list.MinItems(1)
		dnsDomain:     string | *"cluster.local"
	}

	sshAuthorizedKeys: [string, ...]
	sshAuthorizedKeys: list.MinItems(1)

	machines: [Name=_]: #Machine & {
		name: Name
	}
}
