#!/bin/bash
helm repo remove metallb
helm uninstall metallb -n metallb-system

helm repo remove jetstack
helm uninstall cert-manager -n cert-manager

helm repo remove ingress-nginx
helm uninstall ingress-nginx -n ingress-nginx

helm repo remove cert-manager-alidns-webhook
helm uninstall alidns-webhook -n cert-manager

kubectl delete ns metallb-system
kubectl delete ns cert-manager
kubectl delete ns ingress-nginx
kubectl delete ns wow