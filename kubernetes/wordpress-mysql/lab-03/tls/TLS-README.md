# TLS Setup for Kubernetes Lab 3

This directory contains resources for setting up TLS certificates for the WordPress application using cert-manager and Let's Encrypt.

## Prerequisites

Before applying these configurations, cert-manager must be installed in your cluster:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl -n cert-manager wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager
```

## ClusterIssuer Resources

This directory contains two ClusterIssuer resources:

1. `cluster-issuer-staging.yaml`: For testing with Let's Encrypt staging environment (doesn't count against rate limits, but produces untrusted certificates)
2. `cluster-issuer.yaml`: For production use with Let's Encrypt production environment

## Usage Instructions

1. Customize the email address in both ClusterIssuer files
2. Apply the staging issuer first for testing:
   ```bash
   kubectl apply -f cluster-issuer-staging.yaml
   ```
3. Test with your Ingress by setting the annotation:
   ```yaml
   cert-manager.io/cluster-issuer: "letsencrypt-staging"
   ```
4. Once you've confirmed it works, switch to the production issuer:
   ```bash
   kubectl apply -f cluster-issuer.yaml
   ```
5. Update your Ingress to use the production issuer:
   ```yaml
   cert-manager.io/cluster-issuer: "letsencrypt-prod"
   ```

## Certificate Verification

To check the status of your certificates:

```bash
kubectl get certificates -n lab3
kubectl get certificaterequests -n lab3
kubectl get challenges -n lab3
```

## Troubleshooting

If certificates are not being issued:

1. Check the cert-manager logs:
   ```bash
   kubectl logs -n cert-manager -l app=cert-manager
   ```
2. Verify the Certificate resource:
   ```bash
   kubectl describe certificate wordpress-tls -n lab3
   ```
3. Ensure your domain is publicly accessible and that the Ingress controller is properly configured
