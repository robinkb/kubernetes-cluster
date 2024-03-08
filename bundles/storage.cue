cluster: _

bundle: {
	apiVersion: "v1alpha1"
	name:       "storage-system"

	instances: {
		longhorn: {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
			namespace: "storage-system"
			values: {
				repository: url: "https://charts.longhorn.io"
				chart: {
					name:    "longhorn"
					version: "1.5.1"
				}
				helmValues: {
					global: {
						cattle: {
							systemDefaultRegistry: "docker.io"
						}
					}

					// https://longhorn.io/docs/1.5.1/references/settings/
					defaultSettings: {
						// == WARNING WARNING WARNING WARNING WARNING ==
						// Set to true before uninstalling Longhorn. Leads to data loss.
						deletingConfirmationFlag: false
						// == WARNING WARNING WARNING WARNING WARNING ==

						// Defaults to 0, which means disabled. I should look into enabling this
						// if upgrades seem to go smoothly.
						concurrentAutomaticEngineUpgradePerNodeLimit: 0
						// This is very application-dependent, and so should be set through the StorageClass.
						defaultDataLocality: "disabled"
						// Ignition config is setup so that there is an empty partition mounted on this path.
						// Will need to change this if I ever want to support multiple disks.
						defaultDataPath: "/var/lib/longhorn"
						// Force-delete pods on down nodes so that the volume can be released and replacements scheduled.
						nodeDownPodDeletionPolicy: "delete-both-statefulset-and-deployment-pod"

						// Rebuilding replicas faster sounds good?
						fastReplicaRebuildEnabled: true
						// Check for data integrity even when no snapshots are created. Can detect bit rot.
						snapshotDataIntegrity: "enabled"
						// Check integrity at 2:00 on every 7th day of the month.
						snapshotDataIntegrityCronjob: "0 2 */7 * *"

						// Good to know that this exists in case it's ever a problem.
						orphanAutoDeletion: false

						// If a volume is detached, Longhorn will attach it to perform backups/snapshots.
						// If the workload comes back online while Longhorn is using the volume, the workload has to wait.
						allowRecurringJobWhileVolumeDetached: true

						// TODO: Enable overriding variables per environment and default this to false.
						// allowVolumeCreationWithDegradedAvailability: false

						// Try to balance replicas across different nodes for best availability.
						replicaAutoBalance: "best-effort"
						// Longhorn has a dedicated disk (partition...), so no need to reserve space.
						storageReservedPercentageForDefaultDisk: "0"

						// ~~ Danger Zone ~~
						// TODO: Define priority classes and set one here.
						// priorityClass: ""
					}

					persistence: {
						// Avoid using the included Longhorn storage.class by default.
						defaultClass: false
					}
				}
			}
		}

		"longhorn-resources": {
			module: url: "file://../modules/cluster/storage-system/longhorn-resources"
			namespace: "storage-system"
		}
	}
}
