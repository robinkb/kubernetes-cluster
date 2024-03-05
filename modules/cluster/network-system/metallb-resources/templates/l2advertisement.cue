package templates

import (
    metallb "metallb.io/l2advertisement/v1beta1"
)

#L2Advertisement: metallb.#L2Advertisement & {
    #config: #Config
    metadata: {
        name: "local"
        namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
    }
    spec: metallb.#L2AdvertisementSpec & {
        ipAddressPools: [
            #IPAddressPoolLoadBalancers.metadata.name
        ]
    }
}
