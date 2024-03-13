package templates

import (
	storage "k8s.io/api/storage/v1"
)

#StorageClass: storage.#StorageClass & {
	#config: #Config
	#name:   string
	#backup: bool | *false
	#parameters!: {[string]: string}

	apiVersion: "storage.k8s.io/v1"
	kind:       "StorageClass"
	metadata: {
		name:   #name
		labels: #config.metadata.labels
	}
	provisioner: "driver.longhorn.io"

	reclaimPolicy:        "Delete"
	allowVolumeExpansion: true
	volumeBindingMode:    storage.#VolumeBindingWaitForFirstConsumer

	parameters: #parameters
}
