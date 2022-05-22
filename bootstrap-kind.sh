cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

kubectl create ns ping


kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=ready deployment \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Should get from the server rather than be secrets
kubectl create secret generic opa-policy --from-file services/ping/policy.rego -n ping


kubectl create configmap proxy-config --from-file services/ping/envoy.yaml -n ping

kubectl apply -f services/ping/deployment.yaml
kubectl apply -f services/ping/svc.yaml
kubectl apply -f services/ping/ingress.yaml

echo "Waiting for components to become ready"
kubectl wait --for=condition=available --timeout=300s deployment/ping-server -n ping
sleep 15


# should pass
curl -ivvv  http://127.0.0.1/ping
# should fail
curl -ivvv  http://127.0.0.1/pong