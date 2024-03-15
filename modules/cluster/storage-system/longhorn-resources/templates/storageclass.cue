package templates

import (
	"encoding/json"

	storage "k8s.io/api/storage/v1"
)

#StorageClass: storage.#StorageClass & {
	#config:    #Config
	#name:      string
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

	parameters: {
		numberOfReplicas: string

		fsType:                 "ext4"
		disableRevisionCounter: string | *"false"
	}
}

#BlockStorageClass: #StorageClass & {
	parameters: {
		staleReplicaTimeout: "10"
		dataLocality:        string | *"best-effort"
	}
}

#FileStorageClass: #StorageClass & {
	parameters: {
		staleReplicaTimeout:    "2880"
		nfsOptions:             "vers=4.1,noresvport,softerr,timeo=600,retrans=5"
		dataLocality:           "disabled"
		disableRevisionCounter: "false"
	}
}

#StorageClassWithBackup: #StorageClass & {
	#config: #Config
	parameters: {
		recurringJobSelector: json.Marshal({name: "backup", isGroup: true})
		encrypted:                                          "true"
		"csi.storage.k8s.io/provisioner-secret-name":       "longhorn-crypto-key"
		"csi.storage.k8s.io/provisioner-secret-namespace":  #config.metadata.namespace
		"csi.storage.k8s.io/node-publish-secret-name":      "longhorn-crypto-key"
		"csi.storage.k8s.io/node-publish-secret-namespace": #config.metadata.namespace
		"csi.storage.k8s.io/node-stage-secret-name":        "longhorn-crypto-key"
		"csi.storage.k8s.io/node-stage-secret-namespace":   #config.metadata.namespace
	}
}

#BlockStorageClassWithBackup: #BlockStorageClass & #StorageClassWithBackup
#FileStorageClassWithBackup:  #FileStorageClass & #StorageClassWithBackup
