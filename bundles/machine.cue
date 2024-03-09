cluster: _

bundle: {
	apiVersion: "v1alpha1"
	name:       "machine-system"

	instances: {
		"matchbox": {
			module: url: "file://../modules/cluster/machine-system/matchbox"
			namespace: "machine-system"
		}
	}
}
