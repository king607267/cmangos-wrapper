#!/bin/bash
helm repo add metallb https://metallb.github.io/metallb
helm upgrade --install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace

helm repo add jetstack https://charts.jetstack.io
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

helm repo add cert-manager-alidns-webhook https://devmachine-fr.github.io/cert-manager-alidns-webhook
helm upgrade --install alidns-webhook cert-manager-alidns-webhook/alidns-webhook \
  --namespace cert-manager \
  --set image.repository=king607267/alidns-webhook \
  --set image.tag=latest

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: dns-secret
  namespace: cert-manager
data:
  access-key: ${accessKey}
  secret-key: ${secretKey}
EOF

kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: cert-manager
spec:
  acme:
    email: ${issuerEmail}
    server: ${issuerServer}
    privateKeySecretRef:
      name: letsencrypt
    solvers:
      - dns01:
          webhook:
            config:
              accessTokenSecretRef:
                key: access-key
                name: dns-secret
              regionId: cn-beijing
              secretKeySecretRef:
                key: secret-key
                name: dns-secret
            groupName: example.com # groupName must match the one configured on webhook deployment (see Helm chart's values) !
            solverName: alidns-solver
EOF

kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ${metallbPoolName}
  namespace: metallb-system
spec:
  addresses:
    - ${metallbIpPool}
EOF

kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advsement
  namespace: metallb-system
spec:
  ipAddressPools:
    - ${metallbPoolName}
EOF

kubectl wait --for=condition=Ready pod --all -n ingress-nginx --timeout=300s
kubectl wait --for=condition=Ready pod --all -n metallb-system --timeout=300s