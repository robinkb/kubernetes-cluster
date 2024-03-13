package templates

import (
	"encoding/json"

	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	// By default, the minimum Kubernetes version is set to 1.20.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	// The `metadata.name` and `metadata.namespace` fields are
	// set from the user-supplied instance name and namespace.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// The labels allows adding `metadata.labels` to all resources.
	// The `app.kubernetes.io/name` and `app.kubernetes.io/version` labels
	// are automatically generated and can't be overwritten.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// Test Job disabled by default.
	test: {
		enabled: *false | bool
	}
}

#storageClasses: {
	"lh-block-nvme-r1": {
		numberOfReplicas:       "1"
		staleReplicaTimeout:    "10"
		fsType:                 "ext4"
		dataLocality:           "strict-local"
		disableRevisionCounter: "true"
	}
	"lh-block-nvme-r2": {
		numberOfReplicas:       "2"
		staleReplicaTimeout:    "10"
		fsType:                 "ext4"
		dataLocality:           "best-effort"
		disableRevisionCounter: "false"
	}
	"lh-block-nvme-r3": {
		numberOfReplicas:       "3"
		staleReplicaTimeout:    "10"
		fsType:                 "ext4"
		dataLocality:           "best-effort"
		disableRevisionCounter: "false"
	}
	"lh-block-nvme-r3-backup": #backupParameters & {
		numberOfReplicas:       "3"
		staleReplicaTimeout:    "10"
		fsType:                 "ext4"
		dataLocality:           "best-effort"
		disableRevisionCounter: "false"
	}
	"lh-file-nvme-r1": {
		numberOfReplicas:       "1"
		staleReplicaTimeout:    "2880"
		fsType:                 "ext4"
		nfsOptions:             "vers=4.1,noresvport,softerr,timeo=600,retrans=5"
		dataLocality:           "disabled"
		disableRevisionCounter: "true"
	}
	"lh-file-nvme-r2": {
		numberOfReplicas:       "2"
		staleReplicaTimeout:    "2880"
		fsType:                 "ext4"
		nfsOptions:             "vers=4.1,noresvport,softerr,timeo=600,retrans=5"
		dataLocality:           "disabled"
		disableRevisionCounter: "false"
	}
	"lh-file-nvme-r3": {
		numberOfReplicas:       "3"
		staleReplicaTimeout:    "2880"
		fsType:                 "ext4"
		nfsOptions:             "vers=4.1,noresvport,softerr,timeo=600,retrans=5"
		dataLocality:           "disabled"
		disableRevisionCounter: "false"
	}
	"lh-file-nvme-r3-backup": #backupParameters & {
		numberOfReplicas:       "3"
		staleReplicaTimeout:    "2880"
		fsType:                 "ext4"
		nfsOptions:             "vers=4.1,noresvport,softerr,timeo=600,retrans=5"
		dataLocality:           "disabled"
		disableRevisionCounter: "false"
	}
}

#backupParameters: {[string]: string} & {
	recurringJobSelector: json.Marshal({name: "backup", isGroup: true})
	encrypted:                                          "true"
	"csi.storage.k8s.io/provisioner-secret-name":       "longhorn-crypto-key"
	"csi.storage.k8s.io/provisioner-secret-namespace":  "storage-system"
	"csi.storage.k8s.io/node-publish-secret-name":      "longhorn-crypto-key"
	"csi.storage.k8s.io/node-publish-secret-namespace": "storage-system"
	"csi.storage.k8s.io/node-stage-secret-name":        "longhorn-crypto-key"
	"csi.storage.k8s.io/node-stage-secret-namespace":   "storage-system"
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		password: #Password & {#config: config}
		externalsecret: #ExternalSecret & {#config: config}

		for name, parameters in #storageClasses {
			"sc-\(name)": #StorageClass & {#config: config, #name: name, #parameters: parameters}
		}
	}

	tests: {}
}
