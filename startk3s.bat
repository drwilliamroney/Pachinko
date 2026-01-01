@echo off
set HELM_EXE="c:\users\wrone\Downloads\helm"
set K3S_EXE="c:\users\wrone\Downloads\k3d-windows-amd64"
set K3S_HOME=/users/wrone/OneDrive/Desktop/FullSuite/k3shome

echo Starting K3s Cluster (1x5)
%K3S_EXE% cluster create slinkycluster --api-port 127.0.0.1:6445 --servers 1 --agents 5 --volume "%K3S_HOME%:/code@agent:0" --port "8080:80@loadbalancer"
kubectl get nodes

echo INSTALLING SLINKY/SLURM
%HELM_EXE% repo add prometheus-community https://prometheus-community.github.io/helm-charts
%HELM_EXE% repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
%HELM_EXE% repo add bitnami https://charts.bitnami.com/bitnami
%HELM_EXE% repo add jetstack https://charts.jetstack.io
%HELM_EXE% repo update

echo INSTALLING Cert Manager
%HELM_EXE% install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set "crds.enabled=true"

echo INSTALLING Prometheus/Grafana
%HELM_EXE% install prometheus prometheus-community/kube-prometheus-stack --namespace prometheus --create-namespace --set "installCRDs=true"

