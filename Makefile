# Makefile for Home AI Cluster

.PHONY: all build build-clip build-embedding k8s-apply k8s-delete clean

all: build k8s-apply

build: build-clip build-embedding

build-clip:
	cd clip-service && docker build -t clip-service:latest .

build-embedding:
	cd embedding-service && docker build -t embedding-service:latest .

k8s-apply:
	kubectl apply -f pv.yaml
	kubectl apply -f pvc.yaml
	kubectl apply -f vllm-deployment.yaml
	kubectl apply -f vllm-service.yaml
	kubectl apply -f qdrant-deployment.yaml
	kubectl apply -f qdrant-service.yaml
	kubectl apply -f clip-deployment.yaml
	kubectl apply -f clip-service.yaml
	kubectl apply -f embedding-deployment.yaml
	kubectl apply -f embedding-service.yaml

k8s-delete:
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

clean: k8s-delete 