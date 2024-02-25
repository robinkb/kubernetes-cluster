// Code generated by timoni. DO NOT EDIT.

//timoni:generate timoni vendor crd -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml

package v1beta2

import "strings"

// OCIRepository is the Schema for the ocirepositories API
#OCIRepository: {
	// APIVersion defines the versioned schema of this representation
	// of an object. Servers should convert recognized schemas to the
	// latest internal value, and may reject unrecognized values.
	// More info:
	// https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
	apiVersion: "source.toolkit.fluxcd.io/v1beta2"

	// Kind is a string value representing the REST resource this
	// object represents. Servers may infer this from the endpoint
	// the client submits requests to. Cannot be updated. In
	// CamelCase. More info:
	// https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
	kind: "OCIRepository"
	metadata!: {
		name!: strings.MaxRunes(253) & strings.MinRunes(1) & {
			string
		}
		namespace!: strings.MaxRunes(63) & strings.MinRunes(1) & {
			string
		}
		labels?: {
			[string]: string
		}
		annotations?: {
			[string]: string
		}
	}

	// OCIRepositorySpec defines the desired state of OCIRepository
	spec!: #OCIRepositorySpec
}

// OCIRepositorySpec defines the desired state of OCIRepository
#OCIRepositorySpec: {
	certSecretRef?: {
		// Name of the referent.
		name: string
	}

	// Ignore overrides the set of excluded patterns in the
	// .sourceignore format (which is the same as .gitignore). If not
	// provided, a default will be used, consult the documentation
	// for your version to find out what those are.
	ignore?: string

	// Insecure allows connecting to a non-TLS HTTP container
	// registry.
	insecure?: bool

	// Interval at which the OCIRepository URL is checked for updates.
	// This interval is approximate and may be subject to jitter to
	// ensure efficient use of resources.
	interval: =~"^([0-9]+(\\.[0-9]+)?(ms|s|m|h))+$"

	// LayerSelector specifies which layer should be extracted from
	// the OCI artifact. When not specified, the first layer found in
	// the artifact is selected.
	layerSelector?: {
		// MediaType specifies the OCI media type of the layer which
		// should be extracted from the OCI Artifact. The first layer
		// matching this type is selected.
		mediaType?: string

		// Operation specifies how the selected layer should be processed.
		// By default, the layer compressed content is extracted to
		// storage. When the operation is set to 'copy', the layer
		// compressed content is persisted to storage as it is.
		operation?: "extract" | "copy"
	}

	// The provider used for authentication, can be 'aws', 'azure',
	// 'gcp' or 'generic'. When not specified, defaults to 'generic'.
	provider?: "generic" | "aws" | "azure" | "gcp" | *"generic"

	// The OCI reference to pull and monitor for changes, defaults to
	// the latest tag.
	ref?: {
		// Digest is the image digest to pull, takes precedence over
		// SemVer. The value should be in the format 'sha256:<HASH>'.
		digest?: string

		// SemVer is the range of tags to pull selecting the latest within
		// the range, takes precedence over Tag.
		semver?: string

		// Tag is the image tag to pull, defaults to latest.
		tag?: string
	}
	secretRef?: {
		// Name of the referent.
		name: string
	}

	// ServiceAccountName is the name of the Kubernetes ServiceAccount
	// used to authenticate the image pull if the service account has
	// attached pull secrets. For more information:
	// https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#add-imagepullsecrets-to-a-service-account
	serviceAccountName?: string

	// This flag tells the controller to suspend the reconciliation of
	// this source.
	suspend?: bool

	// The timeout for remote OCI Repository operations like pulling,
	// defaults to 60s.
	timeout?: =~"^([0-9]+(\\.[0-9]+)?(ms|s|m))+$" | *"60s"

	// URL is a reference to an OCI artifact repository hosted on a
	// remote container registry.
	url: =~"^oci://.*$"

	// Verify contains the secret name containing the trusted public
	// keys used to verify the signature and specifies which provider
	// to use to check whether OCI image is authentic.
	verify?: {
		// MatchOIDCIdentity specifies the identity matching criteria to
		// use while verifying an OCI artifact which was signed using
		// Cosign keyless signing. The artifact's identity is deemed to
		// be verified if any of the specified matchers match against the
		// identity.
		matchOIDCIdentity?: [...{
			// Issuer specifies the regex pattern to match against to verify
			// the OIDC issuer in the Fulcio certificate. The pattern must be
			// a valid Go regular expression.
			issuer: string

			// Subject specifies the regex pattern to match against to verify
			// the identity subject in the Fulcio certificate. The pattern
			// must be a valid Go regular expression.
			subject: string
		}]

		// Provider specifies the technology used to sign the OCI
		// Artifact.
		provider: "cosign" | *"cosign"
		secretRef?: {
			// Name of the referent.
			name: string
		}
	}
}