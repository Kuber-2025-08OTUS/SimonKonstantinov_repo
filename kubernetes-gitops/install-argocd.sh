#!/bin/bash
# Команда для установки ArgoCD с помощью Helm-чарта

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values argocd-values.yaml


