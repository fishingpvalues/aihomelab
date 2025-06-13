#!/bin/bash
# Clean up all Kubernetes resources for the home AI cluster
set -e
kubectl delete -f embedding-service.yaml --ignore-not-found
kubectl delete -f embedding-deployment.yaml --ignore-not-found
kubectl delete -f clip-service.yaml --ignore-not-found
kubectl delete -f clip-deployment.yaml --ignore-not-found
kubectl delete -f qdrant-service.yaml --ignore-not-found
kubectl delete -f qdrant-deployment.yaml --ignore-not-found
kubectl delete -f vllm-service.yaml --ignore-not-found
kubectl delete -f vllm-deployment.yaml --ignore-not-found
kubectl delete -f pvc.yaml --ignore-not-found
kubectl delete -f pv.yaml --ignore-not-found 