package templates

import (
	certificate "cert-manager.io/certificate/v1"
	issuer "cert-manager.io/issuer/v1"
)

#CACertificate: certificate.#Certificate & {
	#config: #Config
	metadata: {
		name:      "matchbox-root-ca"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: certificate.#CertificateSpec & {
		isCA:       true
		commonName: "Matchbox Root CA"
		dnsNames: ["root.matchbox.cluster.local"]
		secretName: "matchbox-root-ca"
		privateKey: {
			algorithm: "ECDSA"
			size:      256
		}
		issuerRef: {
			group: "cert-manager.io"
			kind:  "ClusterIssuer"
			name:  "self-signed"
		}
		usages: [
			"cert sign",
			"crl sign",
		]
	}
}

#CAIssuer: issuer.#Issuer & {
	#config: #Config
	metadata: {
		name:      "matchbox-root-ca"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: issuer.#IssuerSpec & {
		ca: secretName: "matchbox-root-ca"
	}
}

#ServerCertificate: certificate.#Certificate & {
	#config: #Config
	metadata: {
		name:      "matchbox-server"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: certificate.#CertificateSpec & {
		isCA:       true
		commonName: "Matchbox Server"
		secretName: "matchbox-server"
		// TODO: Should be name of the RPC service
		dnsNames: [
			"matchbox-rpc",
			"matchbox-rpc.machine-system",
			"matchbox-rpc.machine-system.svc",
			"matchbox-rpc.machine-system.svc.cluster.local",
		]
		privateKey: {
			algorithm: "ECDSA"
			size:      256
		}
		issuerRef: {
			group: "cert-manager.io"
			kind:  "Issuer"
			name:  "matchbox-root-ca"
		}
		usages: [
			"server auth",
		]
	}
}

#ClientCertificate: certificate.#Certificate & {
	#config: #Config
	metadata: {
		name:      "matchbox-client"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: certificate.#CertificateSpec & {
		isCA:       true
		commonName: "Matchbox Client"
		secretName: "matchbox-client"
		privateKey: {
			algorithm: "ECDSA"
			size:      256
		}
		issuerRef: {
			group: "cert-manager.io"
			kind:  "Issuer"
			name:  "matchbox-root-ca"
		}
		usages: [
			"client auth",
		]
	}
}
