package templates

import (
	metallb "metallb.io/ipaddresspool/v1beta1"
)

#IPAddressPoolLoadBalancers: metallb.#IPAddressPool & {
    #config: #Config
    metadata: {
        name: "loadbalancers"
        namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
    }
    spec: metallb.#IPAddressPoolSpec & {
        addresses: [#config.loadBalancerRange]
    }
}
